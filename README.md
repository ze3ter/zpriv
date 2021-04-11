hello
The root account on Linux systems provides full administrative level access to the operating system.
During an assessment, you may gain a low-privileged shell on a Linux host and need to perform privilege
escalation to the root account. Fully compromising the host would allow us to capture traffic and access
sensitive files, which may be used to further access within the environment. Additionally, if the Linux
machine is domain joined, we can gain the NTLM hash and begin enumerating and attacking Active Directory.

Enumeration
Enumeration is the key to privilege escalation. Several helper scripts (such as LinEnum) exist to assist 
with enumeration. Still, it is also important to understand what pieces of information to look for and to 
be able to perform your enumeration manually. When you gain initial shell access to the host, it is important 
to check several key details.

OS Version: Knowing the distribution (Ubuntu, Debian, FreeBSD, Fedora, SUSE, Red Hat, CentOS, etc.) will give 
you an idea of the types of tools that may be available. This would also identify the operating system version, 
for which there may be public exploits available.

Kernel Version: As with the OS version, there may be public exploits that target a vulnerability in a specific 
kernel version. Kernel exploits can cause system instability or even a complete crash. Be careful running these 
against any production system, and make sure you fully understand the exploit and possible ramifications before 
running one.

Running Services: Knowing what services are running on the host is important, especially those running as root. 
A misconfigured or vulnerable service running as root can be an easy win for privilege escalation. Flaws have 
been discovered in many common services such as Nagios, Exim, Samba, ProFTPd, etc. Public exploit PoCs exist 
for many of them, such as CVE-2016-9566, a local privilege escalation flaw in Nagios Core < 4.2.4.
```
git clone https://github.com/MO7AMED-SALM/MO7AMED-SALM.git
    cd MO7AMED-SALM
    chmod +x ze3ter.sh
    ./ze3ter.sh
    ```
