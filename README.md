# TLS everywhere
Automatically deploy and renew trusted TLS certificates on a private network

## The Goal

My goal is to be able to **automatically** renew TLS certificates, from a **trusted source**, on all the services in my home network, **without having to expose** any of my servers to the internet. The list of services includes a "[BackupPC](https://backuppc.github.io/backuppc)" server, a "[Proxmox](https://www.proxmox.com/)" server, services on a [Kubernetes](https://kubernetes.io/) cluster and a [Home Assistant OS](https://www.home-assistant.io/) running on a Raspberry Pi.

## TL;DR;

1. Make sure you have a domain and a DNS service that provides an API to automate the DNS-01 challenge
1. Prepare a server in your network with access to the internet (not from, mind you), and to the destination servers, those you wish to protect with TLS. None of them needs to be exposed to the internet
1. Create a user on your certificate server and share its rsa keys with the destination servers, and back
1. Install `certbot` on the certificate server
1. Modify the `authorized_keys` files on the destination servers so that the certificate server's user can trigger a script, but not login.
1. Copy files from the `local_files` directory in this repo to `/opt/certs_distrib/` in the certificate server
1. Copy files from the `server_files` directory in this repo to `/opt/certs_distrib/` in the appropiate destination server
1. Review all the scripts and make your changes (e.g. username and domain name must probably be changed)
1. Request a certificate from Let's Encrypt with `certbot`, using the `--deploy-hook` parameter
1. Watch your certificate be automagically issued and deployed to all configured destinations
1. Wait 3 months to see how your certificate renews and deploys itself without your intervention

## Prereqs

### Public domain

I have chosen [Let's Encrypt](https://letsencrypt.org/) as a trusted source because it allows you to get a certificate using a DNS-01 challenge, which means you do not need to expose anything to the internet to have a certificate issued for your domain. To be able to do that, though, your internal network must be using a public domain, not a ".local", ".test" or similar. Throughout this guide I'll refer to it as `yourdomain.tld`, and you should replace that with your own `.com`, or `.home`, or whatever domain you have purchased.

My new domain I bought from [Godaddy.com](https://www.godaddy.com/), and moved the DNS from there to a free [Cloudflare.com](https://www.cloudflare.com/) account, which provides an API that is supported by both `certbot`, the official Let's Encrypt tool, and `cert-manager`, the (arguably) de facto standard for certificate management on Kubernetes clusters. Instructions on Cloudflare's site are really simple and straightforward.

### Central server

I repurposed an old Raspberry Pi 3 B+, with Debian 10, and use it as a central hub for the certificates. Let's call this "server" `certmanager`. It will connect to Let's Encrypt using [`certbot`](https://certbot.eff.org/) to get certificates (and later renew them), and then will push them, sort of, to all the needed places in my network. I have build this circuit with wildcard certificates in mind, but it could easily be adapted to subdomain certificates.

In order to push the certificates, it will `ssh` into each destination server, but never login, where I've configured the `ssh` authorization in such a way that an `ssh` connection triggers the execution of a script, local to the destination server, and closes. This script, then, will `scp` the files from `certmanager` into the right places and will restart any processes that need to be restarted for the changes to take effect.

This way, if `certmanager` is compromised, it cannot be used to get into any other server. And if any destination server is compromised, it could login to `certmanager` only as a harmless unprivileged user: our `mailman`. This is an unprivileged user, no sudo, called `mailman`, that I created on `certmanager` with the sole purpose to assist in the transfer of certificates.

There are a few things we have to do on `certmanager` before we can get certificates issued to our services. Here are the steps to follow.

#### Step 1: install "snap"

The fitst step is to install ***snap*** as per their official instructions for Debian: https://snapcraft.io/docs/installing-snap-on-debian

The following steps were performed by a user with sudo privielges on `certmanager`.

```
~$ sudo apt install snapd

~$ sudo snap install core
```

#### Step 2: install the right flavor of `certbot`

With ***snap*** installed, we proceed to install `certbot`. To install `certbot` on `certmanager` I followed the instructions for the Cloudflare plugin on `cerbot`'s site: https://certbot.eff.org/lets-encrypt/debianbuster-other.

```
~$ sudo snap install --classic certbot

~$ sudo ln -s /snap/bin/certbot /usr/bin/certbot

~$ sudo snap set certbot trust-plugin-with-root=ok

~$ sudo snap install certbot-dns-cloudflare
```

Following the plugin guide, https://certbot-dns-cloudflare.readthedocs.io/en/stable/, I obtain an API Token from Cloudflare and save it on `$HOME/.secrets/certbot/cloudflare.ini`. It looks like this:

```
~$ cat $HOME/.secrets/certbot/cloudflare.ini
dns_cloudflare_api_token = 4L0N657R1N60F61883R15H_4l0n657r1n60f61bb3r15h
~$
```

#### Step 3: test your `certbot` installation

We are now ready to create a test certificate and see if our `certbot` installation is correct:

```
~$ sudo certbot certonly -v \
        --dns-cloudflare \
        --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
        --register-unsafely-without-email \
        --staging \
        -d *.yourdomain.tld
```

Note the `--staging` option. You should get something like this:

```
~$ sudo ls -ltr /etc/letsencrypt/live/yourdomain.tld
total 4
lrwxrwxrwx 1 root root  40 Mar  8 18:22 privkey.pem -> ../../archive/yourdomain.tld/privkey1.pem
lrwxrwxrwx 1 root root  42 Mar  8 18:22 fullchain.pem -> ../../archive/yourdomain.tld/fullchain1.pem
lrwxrwxrwx 1 root root  38 Mar  8 18:22 chain.pem -> ../../archive/yourdomain.tld/chain1.pem
lrwxrwxrwx 1 root root  37 Mar  8 18:22 cert.pem -> ../../archive/yourdomain.tld/cert1.pem
-rw-r--r-- 1 root root 692 Mar  8 18:22 README
```

Congratualtions! Your first set of (staging) certificates has been issued!

Let's now try a fake renewal with `--dry-run`

```
~$ sudo certbot renew --dry-run
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/yourdomain.tld.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Cert not due for renewal, but simulating renewal for dry run
Plugins selected: Authenticator dns-cloudflare, Installer None
Simulating renewal of an existing certificate for *.yourdomain.tld
Performing the following challenges:
dns-01 challenge for yourdomain.tld
Waiting 10 seconds for DNS changes to propagate
Waiting for verification...
Cleaning up challenges

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
new certificate deployed without reload, fullchain is
/etc/letsencrypt/live/yourdomain.tld/fullchain.pem
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Congratulations, all simulated renewals succeeded:
  /etc/letsencrypt/live/yourdomain.tld/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

```

#### Step 4: preparations for the scripts

Before we proceed further, though, we need to create a directory to install the scripts and one for the logs, and make sure the rsa keys from our `mailman` user are available to the scripts.

```
~$ sudo mkdir /opt/certs_distrib

~$ sudo mkdir /var/log/letsencrypt

~$ sudo ln -s /home/mailman/.ssh/id_rsa /opt/certs_distrib/id_rsa
~$ sudo ln -s /home/mailman/.ssh/id_rsa.pub /opt/certs_distrib/id_rsa.pub

```

Further, we will create a `certs` directory on `mailman`'s home from where the destination servers will be able to fetch the certificates via `scp`.

On `/home/mailman`, as user `mailman`

```
mkdir -p certs/yourdomain.tld
```

And, still on `/home/mailman`, as user `mailman` make sure the user has a pair of rsa keys, that will be used for passwordless `ssh` and `scp`.

```
ssh-keygen -t rsa -b 4096
```

### Destination servers

To install the scripts from this repo and to store the logs generated, create a directory under `/opt` on each destination server:

```
~$ sudo mkdir -p /opt/certs_distrib/log
```

Now share the rsa keys from the `certmanager` with each destination server, and vice versa.

Here we must make a distinction based on whether your destination server allows remote root logins or not. Let's tackle first the most complex case: when remote root logins are forbidden.

#### Remote root logins forbidden

This is also the most generic case, since it can be used even if remote root loigns are allowed.

Create a user `mailman` on that server, and add it to your `sudoers` file, allowing it nothing but to execute a certain script.

Let's say this is a "BackupPC" server, and you named your script `/opt/certs_distrib/backuppc_certs.sh`, as I did. You'd add to your `sudoers` a line like this:

```
mailman ALL = (root) NOPASSWD: /opt/certs_distrib/backuppc_certs.sh
```

Now let's share each other's public keys. Create them with `ssh-keygen -t rsa -b 4096` on either machine if they do not exist yet.

Copy the `certmanager`'s `mailman`'s public key, contained in `~/.ssh/id_rsa.pub`, into `mailman`'s `~/.ssh/authorized_keys` on the destination server.

Edit `mailman`'s `~/.ssh/authorized_keys` on the destination server, and add the `command` and some other parameters in front of `ssh-rsa...`, like this:

```
command="sudo /opt/certs_distrib/backuppc_certs.sh", \
no-agent-forwarding, \
no-port-forwarding, \
no-X11-forwarding, \
no-user-rc \
ssh-rsa AAAAB3NzaC1y[..]l0n657r1n60f61883r15h[...]CtWbQrKwK mailman@certmanager
```

Be careful not to modify the key itself! I've destroyed it in this example for obvous reasons.

Next, copy the destination server's `mailman`'s public key into `certmanager`'s `mailman`'s `~/.ssh/authorized_keys`. No need to modify this one.


#### Remote root logins allowed

No need to create a user on the destination server in this case, we will use `mailman` on `certmanager`, and `root` on the destination server.

Let's say this is your "Proxmox" server, and you named your script `/opt/certs_distrib/proxmoxroot_certs.sh`, as I did.

Now let's share each other's public keys. Create them with `ssh-keygen -t rsa -b 4096` on either machine if they do not exist yet.

Copy `certmanager`'s `mailman`'s public key, contained in `~/.ssh/id_rsa.pub`, into `root`'s `~/.ssh/authorized_keys` on the destination server.

Edit `root`'s `~/.ssh/authorized_keys` on the destination server, and add the `command` and some other parameters in front of `ssh-rsa...`, like this:

```
command="/opt/certs_distrib/proxmoxroot_certs.sh", \
no-agent-forwarding, \
no-port-forwarding, \
no-X11-forwarding, \
no-user-rc \
ssh-rsa AAAAB3NzaC1y[...]l0n657r1n60f61883r15h[...]4kmuYdvsHi mailman@certmanager
```

Be careful not to modify the key itself! I've destroyed it in this example for obvous reasons.

Next, copy the destination server's `root`'s public key into `certmanager`'s `mailman`'s `~/.ssh/authorized_keys`. No need to modify this one.

#### MikroTik router

In this case I already had a user in the router acting as admin, and that is what I used for the deployment. The `mkrtkrouter_certs.sh` script in this repo, is nothing other than Alex Mendes' `letsencrypt.sh` script from his repo: https://github.com/alexmbarbosa/mikrotikSSL. I only introduced minor changes and adapt the script variables `ROUTEROS_USER` and `DOMAIN`, and it worked like a charm!

Alex's script was the inspiration for this whole project.

Thank you, Alex!!

## Bootstrapping the circuit

We're almost there. Follow these steps:

1. Copy all the files in the `local_scripts` directory in this repo to `/opt/certs_distrib` on your `certmanager` server. Change owner to `root` and make the `.sh` files executable by owner.

1. Copy each of the `server_scripts` scripts in this repo to `/opt/certs_distrib/` on the appropiate server. Change owner to `root` and make them executable by owner.
  - In the particular case of Home Assistant OS use a path that is kept between container restarts. I created `/addons/TLS_everywhere`, since `/addons` is a persintent volume. Then modify root's `~/.ssh/authorized_keys` so the `command` points at the script in this path.
  - Furthermore, edit `configuration.yaml` and add these lines to the config:
  ```
  # TLS certs
  http:
    ssl_certificate: /ssl/fullchain.pem
    ssl_key: /ssl/privkey.pem
  ```
  - These two steps require the installation of two addons: "File editor" and "Terminal & SSH".

1. Edit the `apaches`, `prxmxs`, `routers`, etc. files as appropiate. See the description at the top of each file.

1. Edit the scripts, all of them, and substitute your own domain name and user name where appropiate.

1. Take a good look at the scripts and make sure you understand what they do, so you can adapt them to your environment if needed.

1. Create any new scripts you might need for other types of destination servers in your network, and add calls to them to the `destins` file.

### Create and distribute new certificate

On your `certmanager` server, whith sudo privileges, run `certbot` with the `--deploy-hook` and `--staging` parameters to test the circuit. Actually, since we already have ben issued staging certificates and they have not expired, `certbot` will not download new ones, so you will have to revoke and delete them first.

```
~$ sudo certbot certonly \
        --dns-cloudflare \
        --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
        --register-unsafely-without-email \
        --deploy-hook /opt/certs_distrib/distrib_certs.sh \
        --staging \
        -d *.yourdomain.tld
```

Or you can run `certbot` without the `--staging`, so the existing certificates will be replaced by production ones. If all goes well, you are done. If not, run it again with the `--staging` parameter, plus `--break-my-certs` so the certificates will be again replaced by test ones. Not very elegant, but it works.

When all is in place, you should check the timer list on you system and `certbot` should be there:

```
~$ sudo systemctl list-timers
NEXT                         LEFT          LAST                         PASSED      UNIT                         ACTIVATES
Mon 2021-03-08 22:31:00 UTC  3h 57min left n/a                          n/a         snap.certbot.renew.timer     snap.certbot.renew.service
[...]

5 timers listed.
Pass --all to see loaded but inactive timers, too.
```

And at the end of your `/etc/letsencrypt/renewal/yourdomain.tld.conf` there should be a line like this:

```
renew_hook = /opt/certs_distrib/distrib_certs.sh
```

Make sure your last run was without the `--staging` parameter, so your certificates are production grade.

If you now run a dry run renew again, you should see this message:

```
Dry run: skipping deploy hook command: /opt/certs_distrib/distrib_certs.sh
```

Your hook is there, ready to distribute your renewed certificates.

## Done!

Refresh your web interfaces and web sites, and all should now be protected by trusted certificates. An they will be renewed automatically, without human intervention.


