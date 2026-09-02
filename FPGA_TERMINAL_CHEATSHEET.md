# FPGA run cheatsheet — Cheshire + CVA6 + Ara on ZCU102

How to stage a test binary, run it on the CVA6/Ara core, and read its output —
by yourself, from the terminal. Written 2026-09-02, matches the current rig.

---

## 0. The mental model (read once)

```
  host PC  ──USB──┬── FT232H  (0403:6014)  →  JTAG  →  loads the .bit into the FPGA
                  └── CP2108  (10c4:ea71)  →  UART  →  a shell on the ZCU102 PS Linux (ARM)

  On the FPGA:  PS (ARM, runs Linux)  ── AXI ──  PL (Cheshire SoC: CVA6 + Ara + LLC + DDR)
```

* You get **one shell**: the PS-Linux shell over the CP2108 serial (via `screen`).
* The **CVA6/Ara program is bare-metal**. It does **not** print to any UART.
  It writes its console text into a **shared DDR mailbox** that the PS reads with
  `devmem`. "Reading the output" = `devmem`-dumping that buffer.
* **`gpio412`** (a PS GPIO) is the CVA6 **reset line**. `1` = held in reset
  (parked), `0` = running.
* You **reprogram the FPGA before every run** — it resets the LLC to a clean
  state and avoids a stale-cache class of bug.
* The **SD card physically moves** between the board's slot and the host's card
  reader. Board sees it as `/mnt/sd` (`/dev/mmcblk0p1`); host sees it as
  `/media/stavros/BOOT`. Moving it is a manual step.

### Key addresses (all read/written from the PS shell with `devmem`)

| addr | meaning | values |
|---|---|---|
| `0x5FFFF010` | **sentinel / exit code** | `0xDEADDEAD` = staged or still running · `0x00000000` = clean PASS · `0x0000000N` = N failed checks (test bins) or exit code N (apps) |
| `0x50000004` | console byte count | number of valid bytes in the buffer below |
| `0x50002000` | console text buffer | the program's printf output, little-endian words |
| `0x50000050` | **trap flag** | `0x7A7A7A7A` = the core trapped · anything else = **no trap** (garbage is not a trap) |
| `0x50000040` | `mcause` | only meaningful if trap flag == `0x7A7A7A7A` |
| `0x50000048` | `mepc` | " |
| `0x5000004C` | `mtval` | on an illegal-instr trap (`mcause=2`) this is the offending instruction word |
| `0x50000070`–`0x50000094` | scratch markers | app-specific progress markers, usually `0` |

> A "trap" is real **only** when `0x50000050` reads `0x7A7A7A7A`. The
> `mcause/mepc/mtval` slots often hold uninitialised DDR (e.g. the recurring
> `0x1B80A28B / 0x24A106A8 / 0x22080688`) — ignore them unless the flag is set.

---

## 1. Connect the console (once per session, or after any USB reseat)

The CP2108 exposes **4** tty nodes and the numbering is **not stable** — after an
SD swap or a reboot the whole block can shift (`ttyUSB0-3` ↔ `ttyUSB1-4`), and the
FT232H sometimes grabs `ttyUSB0`. Always re-check which node is which:

```bash
lsusb | grep -iE '10c4:ea71|0403:6014'          # 10c4:ea71 = console, 0403:6014 = JTAG
ls /dev/ttyUSB*

# map each node to its chip:
for n in /dev/ttyUSB*; do
  p=$(readlink -f "/sys/class/tty/$(basename $n)/device")
  while [ -n "$p" ] && [ ! -e "$p/idVendor" ]; do p=$(dirname "$p"); done
  echo "$n -> $(cat $p/idVendor):$(cat $p/idProduct)"
done
```

Use the **lowest-numbered `10c4` node** for the console. Then:

```bash
screen -dmS board /dev/ttyUSB1 115200      # <-- put the right node here
screen -r board                            # attach; Ctrl-A d to detach
```

Press Enter in the session — you should get a shell prompt. If the CP2108 is
missing from `lsusb` entirely, the console USB dropped (a known effect of the SD
swap) — reseat the CP2108 USB cable.

---

## 2. Check the reset line (before every run)

In the board shell:

```sh
cat /sys/class/gpio/gpio412/direction     # MUST print: out
cat /sys/class/gpio/gpio412/value

# if the gpio dir is missing or direction=in:
echo 412 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio412/direction
echo 1   > /sys/class/gpio/gpio412/value   # park in reset
```

If `direction` is `in`, `echo 0 > value` silently does nothing and **every test
looks like a hang** with all-zero results. This has cost many wasted runs — check
it every time.

---

## 3. Program the FPGA (before every run) — host side

`/tmp/prog.tcl` gets wiped periodically; recreate it if missing:

```bash
cat > /tmp/prog.tcl <<'EOF'
open_hw_manager
connect_hw_server
set t [lindex [get_hw_targets] 0]
open_hw_target $t
set_property PARAM.FREQUENCY 15000000 $t
set d [get_hw_devices xczu9_0]
current_hw_device $d
set_property PROGRAM.FILE {/home/stavros/bitstreams/cheshire_top_xilinx_L4_V2048_LLC128K_FPUH_DMA1_AXI128_noAtomics_noDbg_SPMfix_DMAfix_NaNboxfix_FPRport1fix_20260901.bit} $d
program_hw_devices $d
puts "PROGRAM_DONE"
close_hw_target
disconnect_hw_server
exit
EOF
```

Current bitstream: `...FPRport1fix_20260901.bit`, md5 `a3777f139ee76d74101a01500ec1a11b`.
(4 lanes, VLEN 2048, LLC 128 KiB, FPU-half, FPR-port-1 fix.)

```bash
/tools/Xilinx/Vivado_Lab/2021.1/bin/vivado_lab -mode batch -source /tmp/prog.tcl -nojournal -nolog
```

Takes ~1–2 min. Success = the log contains **`End of startup status: HIGH`**.
If it says "No matching targets found" the FT232H JTAG dropped — reseat its USB
cable and check `lsusb | grep 0403:6014`.

---

## 4. Stage the binary onto DDR

### 4a. Put the binary on the SD card (host side, card in the reader)

```bash
cp /path/to/yourtest.fpga16.bin /media/stavros/BOOT/
md5sum /media/stavros/BOOT/yourtest.fpga16.bin      # verify against the expected md5
sync
umount /media/stavros/BOOT                          # host: release the card
```

Now **physically move the SD card** into the board's slot.

### 4b. Load it into DDR (board shell)

```sh
# (re)mount the card on the board — do this after every physical swap
umount -l /mnt/sd 2>/dev/null
mkdir -p /mnt/sd
mount -t vfat /dev/mmcblk0p1 /mnt/sd
md5sum /mnt/sd/yourtest.fpga16.bin                  # must match the host md5

sh /mnt/sd/k4_app_prep.sh /mnt/sd/yourtest.fpga16.bin
```

`k4_app_prep.sh` does: assert reset (`gpio412=1`) → clear the console-length and
marker regs → set the sentinel to `0xDEADDEAD` → `load` the binary into DDR at
`0x40000000` → **leave the core in reset**. Watch for:

```
LOAD_EXIT=0 LOAD_OUTPUT_LINES=...
STAGED, board HELD IN RESET
K4_APP_PREP_DONE
```

`LOAD_EXIT=0` and `K4_APP_PREP_DONE` = staged OK. Anything else (`FATAL: LOAD
FAILED`) = stop, the DRAM write did not verify.

---

## 5. Run it

```sh
sh /mnt/sd/k4_app_poll.sh 120        # release reset, poll the sentinel for 120 s
```

This sets `gpio412=0` (core starts) and polls `0x5FFFF010` until it leaves
`0xDEADDEAD` or the timeout hits. Output:

```
DONE after 7s, exit code = 0x00000000     <- 0x0 = clean; 0xN = N failures / exit N
POLL_DONE final=0x00000000
```

* `still running/hung after 120s` → see **§8 (hang?)**.
* Pick the timeout to suit the app: vec_test ~15 s, fc_layer16only ~30 s,
  vggnet16 finetune ~60–120 s, conv_layer16only ~30 s.

### Read the result registers (board shell)

```sh
echo "sentinel : $(devmem 0x5FFFF010)"
echo "bytes    : $(devmem 0x50000004)"
echo "trap flag: $(devmem 0x50000050)"      # 0x7A7A7A7A means it trapped
echo "mcause   : $(devmem 0x50000040)"
echo "mepc     : $(devmem 0x50000048)"
echo "mtval    : $(devmem 0x5000004C)"
```

---

## 6. Print the console output

The program's text lives at `0x50002000`, length at `0x50000004`. Read it word by
word and turn the little-endian words back into text.

### Option A — dump straight to readable text on the board (best)

Create this once on the SD card (`/media/stavros/BOOT/k4_console.sh`, from the
host) — then it's always available on the board as `/mnt/sd/k4_console.sh`:

```sh
#!/bin/sh
# Dump the CVA6/Ara DDR console buffer as text.
BUF=0x50002000
n=$(devmem 0x50000004); n=$((n))
echo "=== console: $n bytes ==="
i=0
while [ $i -lt $n ]; do
  w=$(devmem $(printf '0x%X' $((BUF + i)))); v=$((w))
  o0=$(printf '%03o' $((v & 255)))
  o1=$(printf '%03o' $(((v >> 8) & 255)))
  o2=$(printf '%03o' $(((v >> 16) & 255)))
  o3=$(printf '%03o' $(((v >> 24) & 255)))
  printf "\\$o0\\$o1\\$o2\\$o3"
  i=$((i + 4))
done
echo
```

Run it:

```sh
sh /mnt/sd/k4_console.sh
```

It scrolls slowly (the serial console has a deliberate per-char delay) but prints
the program's output verbatim. To also keep a copy on the host: in the *host*
shell, before running it, arm a screen logfile —

```bash
screen -S board -X logfile /tmp/board.log
screen -S board -X log on
#   ... run k4_console.sh in the session ...
screen -S board -X log off
cp /tmp/board.log /home/stavros/sshfs_dir/MYTEST_$(date +%Y%m%d).txt
```

### Option B — raw words on the board, reassemble on the host

Board shell (prints ~1 line per word):

```sh
n=$(( $(devmem 0x50000004) )); i=0
while [ $i -lt $n ]; do devmem $(printf '0x%X' $((0x50002000 + i))); i=$((i+4)); done
```

Host, after capturing that into `/tmp/board.log` via the screen logfile:

```bash
python3 - <<'EOF'
import re, struct
seg = open('/tmp/board.log').read()
w = [int(m, 16) for m in re.findall(r'^0x([0-9A-Fa-f]{8})\s*$', seg, re.M)]
raw = b''.join(struct.pack('<I', x) for x in w)
n = 0x50000004  # or paste the real byte count
print(raw.decode('ascii', errors='replace'))
print('--- words:', len(w))
EOF
```

### Option C — fully driven from the host (no typing in the session)

This is what the automated runs use. `screen -X stuff` sends keystrokes into the
session; it **eats `$`**, so send only literal lines. Pace ~1.1 s/line.

```bash
NB=$(printf '0x%X' 1600)     # <- the real byte count from devmem 0x50000004
python3 -c "
base, n = 0x50002000, $NB
nw = (n + 3)//4
for c in range(0, nw, 8):
    print('; '.join(f'devmem {hex(base+(c+k)*4)}' for k in range(8) if c+k < nw))
" > /tmp/dump.txt

: > /tmp/board.log
screen -S board -X logfile /tmp/board.log ; screen -S board -X log on ; sleep 0.5
screen -S board -X stuff "echo DUMP_START$(printf '\r')" ; sleep 0.5
while IFS= read -r L; do screen -S board -X stuff "$L$(printf '\r')"; sleep 1.1; done < /tmp/dump.txt
sleep 2 ; screen -S board -X stuff "echo DUMP_END$(printf '\r')" ; sleep 2
screen -S board -X log off

python3 -c "
import re, struct
seg = open('/tmp/board.log').read().split('DUMP_START',1)[1].split('DUMP_END',1)[0]
w = [int(m,16) for m in re.findall(r'^0x([0-9A-Fa-f]{8})\s*\$', seg, re.M)]
print(b''.join(struct.pack('<I', x) for x in w)[:$NB].decode('ascii', errors='replace'))
"
```

### Peeking at a live/partial console (visible screen only)

```bash
screen -S board -X hardcopy /tmp/cap.txt ; tail -20 /tmp/cap.txt
```

---

## 7. Park and unmount (end of every run)

Board shell:

```sh
echo 1 > /sys/class/gpio/gpio412/value      # park CVA6 in reset
sync
umount /mnt/sd                              # release the card on the board
```

Then physically move the SD back to the host reader (only when you need to swap
binaries). Host, when done with the card:

```bash
umount /media/stavros/BOOT
```

Leaving the card mounted on both ends, or pulling it while mounted, corrupts the
FAT and can drop the board into a U-Boot PXE loop.

---

## 8. "It hung" — prove it before believing it

An all-zero result (`sentinel=0xDEADDEAD`, `bytes=0`, no trap) is **usually the
reset line**, not a real hang. Checklist:

1. `cat /sys/class/gpio/gpio412/direction` == `out`? (see §2)
2. Did the FPGA actually program? (`End of startup status: HIGH` in the vivado log)
3. Re-run the **known-good harness binary** on the same freshly-programmed
   bitstream:
   ```sh
   sh /mnt/sd/k4_app_prep.sh /mnt/sd/conv_layer16only_noboot.fpga16.bin
   sh /mnt/sd/k4_app_poll.sh 30
   ```
   It must finish with `exit code = 0x00000000` and ~500–900 console bytes. If
   *that* works and your binary doesn't, the hang is real and in your binary.

---

## 9. Gotchas (all learned the hard way)

| symptom | cause / fix |
|---|---|
| every test all-zero, "hang" | `gpio412` direction came back `in` on re-export — `echo out > .../direction` |
| `vivado_lab`: "No matching targets" | FT232H JTAG dropped off USB — reseat its cable, `lsusb \| grep 0403:6014` |
| console `screen` attaches to nothing | wrong `ttyUSB` node — re-map with the idVendor walk in §1; use the lowest `10c4` node |
| CP2108 gone from `lsusb` after SD swap | known — reseat the CP2108 USB cable |
| `/mnt/sd`: "Directory bread failed" / stale | `umount -l /mnt/sd` then `mount -t vfat /dev/mmcblk0p1 /mnt/sd` |
| board in U-Boot PXE loop | SD was pulled while mounted — power-cycle, kill stale host `screen`/`hw_server` |
| `dd`/`hexdump` on `/dev/mem` → "Bad address" | that DDR window only responds to `devmem` (mmap) — use the word-by-word dump |
| `screen -X stuff` loses shell variables | it eats `$` — send only literal command lines, expand vars on the host first |
| `mcause/mepc/mtval` look like a trap | not a trap unless `0x50000050 == 0x7A7A7A7A`; otherwise it's uninitialised DDR |
| `vivado_lab` "Cannot start server on port 3042/3121" | kill the stale `hw_server` process, retry |
| loss prints as a huge number, not `nan` | `-ffast-math` folds the NaN check — "a number" is not proof of "finite" |

---

## 10. One full run, condensed

```bash
# ---- HOST ----
cp mytest.fpga16.bin /media/stavros/BOOT/ && md5sum /media/stavros/BOOT/mytest.fpga16.bin
sync && umount /media/stavros/BOOT
#   >>> move SD to the board <<<
/tools/Xilinx/Vivado_Lab/2021.1/bin/vivado_lab -mode batch -source /tmp/prog.tcl -nojournal -nolog
#   wait for "End of startup status: HIGH"

# ---- BOARD (screen -r board) ----
cat /sys/class/gpio/gpio412/direction                 # out
umount -l /mnt/sd 2>/dev/null; mount -t vfat /dev/mmcblk0p1 /mnt/sd
md5sum /mnt/sd/mytest.fpga16.bin                       # matches host
sh /mnt/sd/k4_app_prep.sh /mnt/sd/mytest.fpga16.bin    # -> K4_APP_PREP_DONE
sh /mnt/sd/k4_app_poll.sh 120                          # -> exit code = 0xN
devmem 0x5FFFF010; devmem 0x50000004; devmem 0x50000050
sh /mnt/sd/k4_console.sh                               # the program's output
echo 1 > /sys/class/gpio/gpio412/value; sync; umount /mnt/sd
```

---

## 11. Reference: what's on the SD card

| file | purpose |
|---|---|
| `k4_app_prep.sh <bin>` | assert reset, clear mailbox, load `<bin>` into DDR, hold reset |
| `k4_app_poll.sh <secs>` | release reset, poll the sentinel, print exit code |
| `k4_console.sh` | (add per §6A) dump the DDR console buffer as text |
| `load` | aarch64 ELF that writes a flat `.bin` into DDR via `/dev/mem` and verifies it |
| `*_noboot.fpga16.bin` | harness-proof binaries — `conv_layer16only_noboot` exits 0 fast |

Binaries are linked at `0x4000_0000`; `load` verifies the first and last word
(e.g. first word `0x001E4197` = an `auipc`).
