# USB Passthrough Setup for Android Phone in VMM / virt-manager

## Purpose

This document records the steps used to pass an Android phone from the host machine into an Ubuntu virtual machine running under **Virtual Machine Manager (VMM / virt-manager / QEMU-KVM)**, then detect the phone using `adb`.

The goal is to allow Flutter/Android development inside the VM using a physical Android phone over USB.

---

## Environment

| Item | Details |
|---|---|
| Virtualization tool | Virtual Machine Manager / virt-manager / QEMU-KVM |
| Guest OS | Ubuntu Linux VM |
| Phone | Samsung phone |
| Host USB detection | `04e8:6860 Samsung Electronics Co., Ltd Galaxy A5 (MTP)` |
| Android SDK path inside VM | `~/Android/Sdk` |
| ADB path inside VM | `~/Android/Sdk/platform-tools/adb` |
| Host sudo rights | Not available |
| VM sudo rights | Available |

---

## Important concept

There are three separate checks:

```text
Host sees phone → VMM redirects phone → VM sees phone → adb sees phone
```

Each step must work before moving to the next one.

---

## 1. Confirm phone is detected on the host

On the **host machine**, connect the phone with USB and run:

```bash
lsusb
```

When the phone was connected, the host showed:

```text
Bus 001 Device 006: ID 04e8:6860 Samsung Electronics Co., Ltd Galaxy A5 (MTP)
```

Later the device number changed:

```text
Bus 001 Device 007: ID 04e8:6860 Samsung Electronics Co., Ltd Galaxy A5 (MTP)
```

This confirmed that the host machine detected the phone.

Important note:

```text
Bus number and device number can change after unplug/replug.
Vendor/Product ID remains useful: 04e8:6860
```

If the phone does not appear in `lsusb`, check:

- USB cable supports data, not charge-only.
- Phone is unlocked.
- USB port is working.
- Try another USB port or cable.

---

## 2. Confirm VM has USB support

In Virtual Machine Manager:

```text
Open VM → View → Details
```

The VM had:

```text
Controller USB.0
Controller Type model: USB 3
```

The left panel also showed:

```text
USB Redirector 1
SpiceVMC
```

This is acceptable. `SpiceVMC` is normal for USB redirection in virt-manager.

---
## 3. Pass phone USB device into VM  

With the VM running (KVM User session) or shut down, try:  

```text
Virtual Machine → Redirect USB Device
``` 
Then select your phone.  

Alternative menu, if available:  

```text
View → Details → Add Hardware → USB Host Device
```  
Select your phone from the list.  

Example names:  
```text
Samsung Android
Google Pixel
Xiaomi Android
Android Composite ADB Interface
```  
Click:  

```text
Finish
```  
---

## 4. First USB redirection problem

From the running VM window (KVM User session):

```text
Virtual Machine → Redirect USB Device
```

Selecting the Samsung phone initially gave an error similar to:

```text
USB REDIRECTION ERROR:
...
1-7: device is in use by another application
```

Meaning:

```text
The host machine was still holding the phone, usually through MTP / file manager / gvfs / adb.
```

Because there was no sudo access on the host, `sudo fuser` could not be used.

---

## 5. Fix: release user-level host processes

Kill background processes responsible for how your Linux system communicates with external devices like smartphones.  

On the **host machine**, run:

```bash
pkill -f gvfsd-mtp
pkill -f gvfs-mtp-volume-monitor
pkill -f gvfs-gphoto2-volume-monitor
pkill -f adb
```

Then:

1. Unplug the USB cable.
2. Plug the phone back in.
3. In Virtual Machine Manager, use:

```text
Virtual Machine → Redirect USB Device → Samsung Galaxy A5 / 04e8:6860
```

After doing this, USB redirection worked without error.

---

## 6. Confirm phone appears inside the VM (3)

Inside the **Ubuntu VM**, run:

```bash
lsusb
```

The phone appeared inside the VM, for example:

```text
Bus 001 Device 003: ID 04e8:6860 Samsung Electronics Co., Ltd Galaxy A5 (MTP)
```

This confirmed:

```text
USB passthrough from host to VM is working.
```

At this point, the remaining issue is ADB detection.  


---

## 7. Check ADB inside the VM

Inside the VM:

```bash
adb devices -l
adb kill-server
adb start-server
adb devices -l
```

The daemon started successfully:

```text
daemon started successfully
```

But initially `adb devices -l` showed only:

```text
List of devices attached
```

with nothing listed below.

Meaning:

```text
The VM saw the phone over USB, but ADB did not yet see it as a debugging device.
```

---

## 8. Check whether phone exposes ADB interface

Inside the VM, run:  

where 04e8:6860 is the phone device id you noted when run lsusb on host machine.  

```bash
lsusb -v -d 04e8:6860 2>/dev/null | grep -i -E "adb|mtp|interface|vendor|class"
```

The observed result showed interfaces such as:

```text
iInterface MTP
iInterface CDC Abstract Control Model (ACM)
iInterface CDC ACM Data
```

But there was **no ADB interface** shown.

Meaning:

```text
The phone was visible as MTP/media, but not yet exposed as an ADB-debuggable device.
```  
At this point look at phone, a USB Setting window is waiting for your interaction.  
---

## 9. Phone USB settings issue

On the phone, USB settings showed:

```text
USB controlled by: 
        This device
Use USB for: (change to)
        Transferring files / Android Auto
```

or similar Samsung wording:

```text
Transferring files
MTP
```

---

## 10. Reset Android USB debugging authorization

Even though USB debugging was already enabled, ADB still did not detect the phone.

On the phone:

```text
1.Settings → About phone → Software information → Build number  
Tap Build number 7 times.    

2.Settings → Developer options → Revoke USB debugging authorizations
3.Settings → Developer options → USB debugging → OFF
4.Settings → Developer options → USB debugging → ON
```

Then:

1. Redirect the Samsung phone again from VMM:

```text
Virtual Machine Manager → Virtual Machine → Redirect USB Device
```
2. Take a look at phone.  

The phone displayed:

```text
Allow USB debugging?
```

The prompt was accepted on the phone.

3. Inside the VM:

```bash
adb kill-server
adb start-server
adb devices -l
```
This time, a <device usb:1-3 ..> appeared in the ADB list. 

**ADB works.**

4. On the phone, USB for file Transfer notification appeared.  

Tap for USB options.  USB settings displays.  

ensure below is selected.  

```text
Transferring files / Android Auto
```
---
## 11. Check Flutter sees the phone
```text
flutter devices
```  
It found 3 connected devices SM A1469 (mobile) , linux (desktop), Chrome(web). 

Then:  
```text
flutter doctor
flutter doctor --android-licenses
flutter doctor
```  
... Connected device ( 3 available)

**Flutter sees the phone.**

---

## 12. Extra confirmation, check phone model, manufacturer, Android version:  

Run this inside the VM:  

```text
adb shell getprop ro.product.model
adb shell getprop ro.product.manufacturer
adb shell getprop ro.build.version.release
```  
Check the current USB ID:   

```text
lsusb | grep -i samsung  
```   
---

# Troubleshooting:  

### 1. If final observed state

After the above fix, `adb devices -l` showed the phone, but the status was:

```text
unauthorized usb:1-3 transport_id:1
```

Meaning:

```text
ADB sees the phone, but the phone authorization is not fully completed yet.
```

This is better than an empty ADB list.

The next expected successful state should be:

```text
List of devices attached
XXXXXXXX    device usb:1-3 transport_id:1
```

where the important word is:

```text
device
```

not:

```text
unauthorized
```

---

## 2. Next steps when USB is available again

Reconnect USB, redirect the phone again into the VM, then run:

```bash
adb kill-server
adb start-server
adb devices -l
```

If it still shows:

```text
unauthorized
```

do this:

1. Keep phone unlocked.
2. Look for the `Allow USB debugging?` prompt.
3. Select:

```text
Always allow from this computer
Allow
```

4. Run again:

```bash
adb devices -l
```

If no prompt appears:

```text
Developer options → Revoke USB debugging authorizations
Developer options → USB debugging OFF
Developer options → USB debugging ON
```

Then reconnect, redirect USB again, and run:

```bash
adb kill-server
adb start-server
adb devices -l
```

---

## 3. If ADB is still unauthorized

Inside the VM, remove old ADB keys:

```bash
rm -f ~/.android/adbkey ~/.android/adbkey.pub
adb kill-server
adb start-server
adb devices -l
```

Then watch the phone for the authorization prompt again.

If needed, restart the VM and repeat:

```text
VMM → Virtual Machine → Redirect USB Device → Samsung phone
```

Then:

```bash
adb devices -l
```

---

## 4. If normal adb has permission issues

In this case, using full ADB path with `sudo` was tested:

```bash
sudo /home/sthiagar/Android/Sdk/platform-tools/adb kill-server
sudo /home/sthiagar/Android/Sdk/platform-tools/adb start-server
sudo /home/sthiagar/Android/Sdk/platform-tools/adb devices -l
```

Earlier, this still did not list the phone, so the issue was not simply Linux permission.

However, if future tests show the phone appears only with `sudo`, add a Samsung udev rule inside the VM:

```bash
sudo nano /etc/udev/rules.d/51-android.rules
```

Add:

```text
SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"
```

Then run:

```bash
sudo chmod a+r /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG plugdev $USER
```

Then reboot the VM and test again:

```bash
adb kill-server
adb start-server
adb devices -l
```

---

## 5. Common meanings of `adb devices -l`

| Output | Meaning | Action |
|---|---|---|
| Empty list | ADB does not see the phone | Check USB mode, redirection, ADB interface |
| `unauthorized` | Phone sees ADB but has not authorized this computer | Accept prompt on phone |
| `device` | ADB is working | Ready for Flutter/Android testing |
| `offline` | ADB connection is stale | Restart adb, reconnect USB |
| `no permissions` | Linux permission issue inside VM | Add udev rule |

---

## 6. Final working sequence summary

Use this sequence next time:

```text
1. Connect phone to host by USB.
2. Host: run lsusb and confirm 04e8:6860 Samsung phone appears.
3. Host: close file manager if it opened the phone.
4. Host: run pkill commands to release MTP/ADB user processes.
5. Unplug and replug phone.
6. VMM: Virtual Machine → Redirect USB Device → Samsung phone.
7. VM: run lsusb and confirm Samsung phone appears inside VM.
8. Phone: set USB mode to File Transfer / Android Auto.
9. Phone: Developer options → Revoke USB debugging authorizations.
10. Phone: USB debugging OFF, then ON.
11. VM: adb kill-server.
12. VM: adb start-server.
13. VM: adb devices -l.
14. Phone: accept Allow USB debugging prompt.
15. VM: adb devices -l again.
```

Expected final result:

```text
List of devices attached
XXXXXXXX    device usb:1-3 transport_id:1
```

---

## 7. After ADB works

Check Flutter:

```bash
flutter devices
```

Then run a Flutter app on the phone:

```bash
cd ~/projects/your_flutter_project
flutter run
```

If multiple devices appear:

```bash
flutter devices
flutter run -d <device_id>
```

Phone device id is R58W123ABC

```bash
SM A146B (mobile) • R58W123ABC • android-arm64 • Android 14
Linux (desktop)   • linux       • linux-x64     • Ubuntu
Chrome (web)      • chrome      • web-javascript
```

Hot reload:

```text
r
```

Hot restart:

```text
R
```

---

