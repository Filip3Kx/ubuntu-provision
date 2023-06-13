# Overview

![Pasted image 20230601141657](https://github.com/Filip3Kx/ubuntu-provision/assets/114138650/eb6f803a-6916-4655-bee7-9f21c51d29eb)

This is a config that will install ubuntu server systems with `predefined` parameters making it an unnatended installation and can also be used to run provisioning scripts of your choice.

DISCLAIMER. This guide shows how to automate a **pendrive installation**. You can use PXE server but you need to foward the `cloud-init` file in the same line that you are appending `initial ram disk` of a PXE boot ISO.

## Prequesites
- [Ventoy](https://github.com/ventoy/Ventoy)
- A thumbdrive
- FTP, NFS or HTTPS server if you want scripts to be fetched from a server 

## Setting up ventoy thumdrive
After downloading newest Ventoy open Ventoy2Disk.exe to install the firmware onto your drive. Simply choose a device and press Install

![Pasted image 20230524143837](https://github.com/Filip3Kx/ubuntu-provision/assets/114138650/aa02e67e-76e2-46ac-9752-87abc2734d13)

## Adding .iso files to the menu
At this point every iso you put in the root directory of a partition called `Ventoy` is going to show up in the menu after you boot using the flash drive

![Pasted image 20230524152145](https://github.com/Filip3Kx/ubuntu-provision/assets/114138650/cc7bbe81-a349-41ed-932a-6397f27dac7c)
![Pasted image 20230524144043](https://github.com/Filip3Kx/ubuntu-provision/assets/114138650/38daefa6-fdd0-4f85-97c9-7591ac54d06c)

## Configuring autoinstallation templates
We will configure our templates using the web application of Ventoy. To access the server you have to plug in your pendrive and run the VentoyPlugson.exe file.

Press start and it should put you in a webapp of ventoy

![Pasted image 20230524151712](https://github.com/Filip3Kx/ubuntu-provision/assets/114138650/7ff8b514-98f0-4a67-9e61-dbdc28452fda)

Go into Auto Install Plugin and set it up using one of the files described below

![Pasted image 20230524152038](https://github.com/Filip3Kx/ubuntu-provision/assets/114138650/836cbb2f-01fd-44b4-b982-52f72519a03d)

## Cloud-init-user-data files

Here is a collection of files that i wrote that can help with basic scenarios of provisioning a fresh ubuntu install.

### Local script execution
The file [cloud-init-local.yaml](https://github.com/Filip3Kx/ubuntu-provision/blob/main/cloud-init-local.yaml) offers you the most basic configuration of cloud init that will automaticaly configure network, disks, user information, and set up an ssh server.

There is also a runcmd block that will run every command inside after the first boot of a freshly installed OS.

This is a one liner that will parse the result of `fdisk -l` and will mount the disk specified in `awk"/DataTraveler/"`. **Be sure to replace "DataTraveler" with your own device name.** 
```bash
sudo mount $(sudo fdisk -l |sed -e '/Disk \/dev\/loop/,+5d' | grep Disk | awk '! /Disk identifier/' | awk '! /Disklabel/' | awk 'NR % 2 == 0 {printf "%s %s\n", p, $0; next} {p=$0}' | awk "/DataTraveler/" | awk '{print $2}' | awk '{sub(/.$/,"")}1')1 /media
```

After the drive is mounted it can run the script available on the disk. 
```bash
sudo /media/DUT_scripts/./configuration.sh
```

### File transfer script execution
Next up is the [cloud-init-ftp.yaml](https://github.com/Filip3Kx/ubuntu-provision/blob/main/cloud-init-ftp.yaml) file that offers fully unnatend provisioning because you don't have to keep the pendrive inserted which can cause some boot order alterations. We will pull the script from an outside server. In this scenario i'm using FTP but any other should work just fine

```bash
sudo bash configuration.sh
```
### Adding interactive parts
If your server instances are unique and you need to enter some parts by hand you can just add the `interactive-sections:` block into the file and specify which parts are meant to be interactive. Example in [cloud-init-interactive.yaml](https://github.com/Filip3Kx/ubuntu-provision/blob/main/cloud-init-interactive.yaml)

## Provisioning script
As you can see all of these files end in running a script. [provision.sh](https://github.com/Filip3Kx/ubuntu-provision/blob/main/provision.sh) is a sample script that will 
- configure the OS proxy 
- Download packages 
- Configure services
- etc.
