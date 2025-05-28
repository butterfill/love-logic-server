---
title: configuring fail2ban on nginx for zoxiy servers
created: 5/27/2025
tags:
  -
projects:
  - lp83px3XHTSxSfSwbOYkn
---

## do not put rate limiting on the main site

E.g. In `/etc/nginx/sites-enabled`, `logic-ex-vu-uk3.zoxiy.xyz` should not have the line `limit_req zone=mylimit burst=5 nodelay;` (I tried with higher limits; just best to leave it out I think).


## allow cloudflare ip range (and zoxiy IPs)

Because everything is proxied via cloudflare,
and because zoxiy requires lots of xhr requests,
setting up fail2ban in the standard way can create problems.

Edit `/etc/fail2ban/jail.local` so that:

```
ignoreip = 127.0.0.1/8 ::1 173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22 141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20 197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13 104.24.0.0/14 172.64.0.0/13 131.0.72.0/22 45.32.157.98 10.0.0.21 45.32.180.114 10.0.0.31 45.32.181.24 10.0.0.32 108.61.196.248 10.0.0.33 78.141.224.145 10.0.0.34 192.248.166.158 10.0.0.35 45.76.129.106 10.0.0.6
```

This is the ip ranges for cloudflare that you can get here: \ref{url:https://www.cloudflare.com/ips/}

The last addresses (45.32.157.98 on) are the internal zoxiy addresses.

## fail2ban config hint

DO NOT PUT COMMENTS ON THE SAME LINE AS CONFIG INFO!!!


## Instructions

the notes below are exported from perplexity, but **modified to correct errors**.

Note that there are two steps:

  - [x] set up nginx rate limiting (\ref{url:https://www.perplexity.ai/search/please-walk-me-through-setting-3XV3buEwSmmERfbfJC6vUA})
  - [x] set up fail2ban (\ref{url:https://www.perplexity.ai/search/please-walk-me-through-setting-VR9aFwUZTxC1FMUx8qb54A})



## STEP 1: nginx rate limiting

To set up Nginx Request Limiting on your Ubuntu server running Nginx 1.10.3, you'll primarily use two directives: `limit_req_zone` and `limit_req`[1]. This feature is part of the `ngx_http_limit_req_module`, which was introduced in Nginx version 0.7.21, so your Nginx 1.10.3 version supports it[2][5]. If you encounter an "unknown directive limit_req_zone" error, it might indicate that the module is not compiled into your Nginx build, which can happen with `nginx-light`. In such cases, installing `nginx-full` using `apt install nginx-full` might be necessary[5].

Here’s a step-by-step guide:

### 1. Define the Rate Limit Zone
You need to define a shared memory zone where Nginx will store the state of client IP addresses and their request frequencies[1][6]. This is done using the `limit_req_zone` directive, typically within the `http` block of your Nginx configuration file (e.g., `/etc/nginx/nginx.conf`)[1][6].

Open your Nginx configuration file:
```bash
sudo vim /etc/nginx/nginx.conf
```

Inside the `http { ... }` block, add a line like this:
```nginx
http {
    # ... other http configurations ...

    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=1r/s;

    # ... other http configurations ...
}
```

Let's break down this directive[1][2][6]:
*   `$binary_remote_addr`: This Nginx variable represents the client's IP address in a binary format, which is more memory-efficient than the string representation (`$remote_addr`)[1][2]. This is the key against which the limit is applied, meaning each unique IP address will be limited[1].
*   `zone=mylimit:10m`: This defines the shared memory zone.
    *   `mylimit` is the name you give to this zone. You'll use this name later to apply the limit[1][6].
    *   `10m` specifies the size of the zone in megabytes. A 1MB zone can hold state for about 16,000 IP addresses on 32-bit systems or 8,000 on 64-bit systems (as each state occupies 64 or 128 bytes respectively)[2]. Adjust the size based on your expected traffic.
*   `rate=1r/s`: This sets the maximum request rate.
    *   `1r/s` means 1 request per second from a single IP address[2][6]. You can also specify rates in requests per minute (r/m), for example, `30r/m` for 30 requests per minute (or half a request per second)[2].

### 2. Apply Rate Limiting
Once the zone is defined, you can apply it within specific `server` or `location` blocks where you want to enforce the limit[1][4]. This is done using the `limit_req` directive.

For example, to limit requests to a `/login/` or `/api/` endpoint:
```nginx
server {
    # ... other server configurations ...

    location /login/ {
        limit_req zone=mylimit burst=5 nodelay;
        # ... other location configurations like proxy_pass ...
        proxy_pass http://my_upstream;
    }

    location /api/ {
        limit_req zone=mylimit burst=10;
        # ... other location configurations ...
    }
}
```

Explanation of `limit_req` parameters[2][3]:
*   `zone=mylimit`: This refers to the shared memory zone you defined earlier[1].
*   `burst=5` (optional): This parameter allows a client to make a certain number of requests (5 in this example) exceeding the defined rate before Nginx starts delaying or rejecting further requests. These "burst" requests are processed quickly. By default, the burst size is zero[2].
*   `nodelay` (optional): If `nodelay` is used with `burst`, Nginx will process the burst requests immediately and then start limiting, but without delaying subsequent requests that are within the burst limit. If `nodelay` is not specified, excessive requests (within the burst limit) are delayed to conform to the average rate[2][3]. If delaying excessive requests is not desired, use `nodelay`[2]. Requests exceeding the burst limit will be rejected (typically with a 503 error)[2][4].

You can have multiple `limit_req` directives if needed, for instance, to apply different limits or to limit based on both IP address and server name[2].

### 3. [no—can ignore] Customize Error Responses (Optional)
By default, Nginx returns a 503 (Service Unavailable) error when a request is rejected due to rate limiting[2][4]. You can change this status code or provide a custom error page[3].

To change the status code to 429 (Too Many Requests):
```nginx
http {
    # ...
    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=1r/s;
    limit_req_status 429; # Sets the status code for rejected requests
    # ...
}
```
The `limit_req_status` directive was introduced in Nginx 1.3.15[2].

To use a custom error page for a 503 error (if you don't change the default status code):
```nginx
server {
    # ...
    location /api/ {
        limit_req zone=mylimit burst=5;
        error_page 503 @ratelimit;
        # ...
    }

    location @ratelimit {
        return 429 "Too Many Requests. Please try again later.";
        # You can also serve an HTML page here
    }
}
```
This example defines a named location `@ratelimit` that returns a 429 status code with a custom message when the original 503 error (due to rate limiting) occurs[3].

### 4. [no—can ignore]  Adjust Logging (Optional)
You can control the logging level for rate-limited requests using `limit_req_log_level`. The default is `error`[2].
```nginx
http {
    # ...
    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=1r/s;
    limit_req_log_level warn; # Log rejections at 'warn', delays at 'info'
    # ...
}
```
Delays are logged one level lower than refusals. For example, if `limit_req_log_level notice;` is specified, delays are logged with the `info` level[2].

### 5. Test Configuration and Restart Nginx
Before applying the changes, it's good practice to test your Nginx configuration:
```bash
sudo nginx -t
```
If the test is successful, restart Nginx to apply the new configuration[6]:
```bash
sudo systemctl restart nginx
```
Or, if your system uses init.d:
```bash
sudo service nginx restart
```

### 6. Dry Run Mode (Optional)
For testing your rate-limiting rules without actually enforcing them, you can use the `limit_req_dry_run` directive (available from Nginx 1.17.1, so not in your 1.10.3 version). In dry run mode, Nginx processes requests as usual but logs what would have been limited[2][4]. Since your Nginx version is 1.10.3, this specific directive is not available.

### 7. Monitor and Test
After configuration, monitor your Nginx logs (access and error logs) to see the rate limiting in action[3][6]. You can use tools like `curl` or load testing tools to send multiple requests and verify that the limits are being enforced as expected[3][6]. For example, sending a burst of requests:
```bash
for i in {1..20}; do curl -I http://your_server_address/login/; done
```
Check the server-side logs to see if requests are processed (e.g., HTTP 200) up to the limit and then delayed or rejected (e.g., HTTP 503 or 429)[6].

Citations:
[1] https://blog.nginx.org/blog/rate-limiting-nginx
[2] http://nginx.org/en/docs/http/ngx_http_limit_req_module.html
[3] https://www.bitslovers.com/how-to-configure-nginx-rate-limit-and-whitelist/
[4] https://docs.nginx.com/nginx/admin-guide/security-controls/controlling-access-proxied-http/
[5] https://serverfault.com/questions/611612/nginx-rate-limiting-unknown-directive-limit-req-zone
[6] https://www.builddevops.com/post/nginx-rate-limit
[7] https://launchpad.net/ubuntu/+source/nginx/1.10.3-0ubuntu0.16.04.3
[8] https://serverfault.com/questions/914304/nginx-installation-error
[9] https://stackoverflow.com/questions/57189150/504-gateway-time-out-nginx-1-10-3-ubuntu
[10] https://icicimov.github.io/blog/devops/NGINX-Naxsi-PageSpeed-LDAP/



## Please walk me through setting fail2ban up. I'm on ubuntu server 16.04.6 running nginx 1.10.3

To set up Fail2ban on your Ubuntu Server 16.04 with Nginx 1.10.3, follow these steps:

### System Preparation and Fail2ban Installation

1. **Update System Packages**:
Before installing new software, ensure your system's package list and installed packages are up to date. Log in as a root user or use `sudo` for these commands[^2][^4].

```bash
apt-get update -y
apt-get upgrade -y
```

Or, if you prefer to see the output before confirming:

```bash
sudo apt-get update
sudo apt-get upgrade
```

Then, install Fail2ban[^1][^2]:

```bash
sudo apt-get install fail2ban -y
```

2. **Start and Check Fail2ban Service**:
Once installed, start the Fail2ban service and verify its status[^1][^6].

```bash
sudo service fail2ban restart
sudo service fail2ban status
```

The output should show `active (running)`[^1].

### Basic Fail2ban Configuration

Fail2ban's main configuration file is `/etc/fail2ban/jail.conf`. However, to avoid changes being overwritten during package updates, you should create a local configuration file `/etc/fail2ban/jail.local` for your customizations[^5].

1. **Create `jail.local`**:
You can copy the default configuration file or create a new one[^1][^5].
To copy the existing `jail.conf`:

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

Alternatively, to create an empty file:

```bash
sudo touch /etc/fail2ban/jail.local
```

2. **Edit `jail.local`**:
Open `/etc/fail2ban/jail.local` with a text editor like `nano` or `vi`[^1][^4].

```bash
sudo nano /etc/fail2ban/jail.local
```

Add or modify the `[DEFAULT]` section. This section sets global policies which can be overridden in specific jails[^5].
Here's a basic example configuration:

```ini
[DEFAULT]
# IPs to ignore (e.g., your own static IP, localhost)
# Add your IP addresses or networks, separated by spaces[^5]
# SEE ABOVE — NEED TO ADD CLOUDFLARE RANGES!
ignoreip = 127.0.0.1/8 ::1

# Time in seconds an IP is banned
bantime = 3600

# Time window in seconds for detecting attacks
findtime = 600

# Number of failed attempts before banning
maxretry = 5

# Enable SSH protection (optional but recommended)
[sshd]
enabled = true
```

    * `ignoreip`: IP addresses that Fail2ban should not ban. `127.0.0.1/8 ::1` refers to localhost addresses[^4].
    * `bantime`: The duration (in seconds) for which an IP is banned (e.g., 3600 seconds = 1 hour)[^4].
    * `findtime`: The time window (in seconds) during which an IP must make `maxretry` attempts to be banned (e.g., 600 seconds = 10 minutes)[^4].
    * `maxretry`: The number of failed login attempts within `findtime` before an IP is banned[^4].

### Nginx Specific Configuration

To protect Nginx, you'll need to configure Nginx to log attempts that Fail2ban can monitor, and then set up a Fail2ban jail for Nginx[^3]. This typically involves using Nginx's `ngx_http_limit_req_module` to limit request rates from IPs, which then logs excessive requests to Nginx's error log[^3].

1. **Configure Nginx Request Limiting**:
You'll need to set up Nginx to limit requests per IP. This configuration goes into your Nginx server block or http block. For details on configuring Nginx's `limit_req` module, you would typically refer to Nginx documentation or specific guides on this topic, as the provided search results focus more on the Fail2ban side[^3]. Nginx will log information about IPs exceeding these limits into its error log, which Fail2ban will then parse[^3].
2. **Create a Fail2ban Filter for Nginx**:
Create a filter file that tells Fail2ban how to identify offending log entries in Nginx's error logs.
Create the file `/etc/fail2ban/filter.d/nginx-req-limit.conf`[^3]:

```bash
sudo nano /etc/fail2ban/filter.d/nginx-req-limit.conf
```

Add the following content. This regular expression (`failregex`) is designed to match lines in Nginx's error log indicating that an IP has exceeded the request limit[^3]:

```ini
# Fail2Ban configuration file for ngx_http_limit_req_module
[Definition]
failregex = limiting requests, excess:.* by zone.*client: <HOST>
ignoreregex =
```

Save and close the file.
3. **Add Nginx Jail to `jail.local`**:
Open `/etc/fail2ban/jail.local` again:

```bash
sudo nano /etc/fail2ban/jail.local
```

Add the following section to enable the Nginx request limiting jail. This configuration tells Fail2ban to use the filter created above, monitor Nginx error logs, and defines actions for banning[^3].

```ini
[nginx-req-limit]
enabled = true
filter = nginx-req-limit
action = iptables-multiport[name=ReqLimit, port="http,https", protocol=tcp]
# Adjust if your Nginx error logs are elsewhere
logpath = /var/log/nginx/*error.log  
findtime = 600
# Ban for 2 hours
bantime = 7200  
# Ban after 10 hits in findtime
maxretry = 10   
```

    * `logpath`: Specifies the location of Nginx error logs. Ensure this path is correct for your Nginx setup[^3].
    * `findtime`, `bantime`, `maxretry`: These can be adjusted. Smaller `findtime` and `maxretry` values will lead to IPs being banned more frequently[^3].



### Restart and Verify Fail2ban

1. **Restart Fail2ban**:
After saving all configuration changes, restart the Fail2ban service to apply them[^3][^5].

```bash
sudo service fail2ban restart
```

2. **Check Status of Jails**:
You can see all enabled jails and their status using the `fail2ban-client` command[^5].

```bash
sudo fail2ban-client status
```

This should list your `sshd` jail and the `nginx-req-limit` jail (and any others you've enabled)[^5].
To check a specific jail, like `nginx-req-limit`[^3]:

```bash
sudo fail2ban-client status nginx-req-limit
```

This will show details like the list of monitored log files, currently failed attempts, and currently banned IPs for that jail[^3].

### Firewall Considerations (UFW)

If you are using UFW (Uncomplicated Firewall), ensure that SSH is allowed to prevent locking yourself out, especially if you are configuring SSH protection with Fail2ban[^4].

```bash
sudo ufw allow ssh
sudo ufw enable
```

Fail2ban interacts with your firewall (by default, iptables) to ban IPs[^5].

### Testing and Debugging

* **Monitor Fail2ban Logs**:
You can watch Fail2ban's own log file for activity, such as IP bans[^3].

```bash
sudo tail -f /var/log/fail2ban.log
```

You should see entries when Fail2ban bans an IP[^3].
* **Debug Filter Regex**:
If you suspect a filter isn't working correctly, you can test its regular expression against a log file[^3]:

```bash
sudo fail2ban-regex /var/log/nginx/error.log /etc/fail2ban/filter.d/nginx-req-limit.conf
```

Replace `/var/log/nginx/error.log` with the actual path to an Nginx error log file. The output will show how many lines matched the `failregex`[^3].
* **Fail2ban Client Debug Output**:
To see detailed configuration used by the Fail2ban server:

```bash
sudo fail2ban-client -d
```

This can help identify misconfigurations[^3].

By following these steps, you will have Fail2ban installed and configured to help protect your Nginx server on Ubuntu 16.04 from excessive requests and other configured threats. Remember to adjust paths and parameters according to your specific server setup and security needs.

<div style="text-align: center">⁂</div>

[^1]: https://www.liquidweb.com/blog/install-configure-fail2ban-ubuntu-server-16-04/

[^2]: https://www.rapid7.com/blog/post/2017/02/13/how-to-protect-ssh-and-apache-using-fail2ban-on-ubuntu-linux/

[^3]: https://easyengine.io/tutorials/nginx/fail2ban/

[^4]: https://www.interserver.net/tips/kb/install-configure-fail2ban-ubuntu/

[^5]: https://www.digitalocean.com/community/tutorials/how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-14-04

[^6]: https://bobcares.com/blog/how-to-install-and-configure-fail2ban-on-ubuntu-server-16-04/

[^7]: https://www.digitalocean.com/community/tutorials/how-to-protect-an-nginx-server-with-fail2ban-on-ubuntu-20-04

[^8]: https://ubuntu101.co.za/nginx/upgrade-nginx-1-12-ubuntu-16-xenial/

[^9]: https://www.servers.com/support/knowledge/linux-administration/how-to-protect-ssh-using-fail2ban-on-ubuntu-16-04

[^10]: https://askubuntu.com/questions/991268/cant-set-up-fail2ban-ubuntu-16-04

