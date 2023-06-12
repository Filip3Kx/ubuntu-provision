# Overview
This is a config that will install ubuntu server systems with `predefined` parameters making it an unnatended installation and can also be used to run provisioning scripts of your choice.

DISCLAIMER. This guide shows how to automate a **pendrive installation**. You can use PXE server but you need to foward the `cloud-init` file in the same line that you are appending `initial ram disk` of a PXE boot ISO.

## Prequesites
- [Ventoy](https://github.com/ventoy/Ventoy)
- A thumbdrive
- FTP, NFS or HTTPS server if you want scripts to be fetched from a server 
