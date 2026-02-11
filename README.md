# **Traefik External Edge Router**

This repository provides a self-contained edge proxy that simplifies managing and routing HTTPS traffic to applications running in other Docker containers.

### **Example Usage on a VPS**

Imagine you have more than one application that you manage for a site. Instead of manually configuring an Nginx server for each application and managing separate SSL certificates, this service functions as a central entry point for HTTPS and (eventually) other edge functions.

1. This Traefik stack runs on your VPS. It manages traffic on a public `web` network.
2. It listens on ports 80 and 443.
3. Your separate application containers are configured to join the same `web` network that Traefik is on.
4. You add labels to your application containers that tell Traefik where to route traffic. For example, a label could say "if the request is for blog.yourdomain.com, send it to this container."
5. Traefik automatically handles the SSL certificates for your domains (blog.yourdomain.com, portfolio.yourdomain.com) using Let's Encrypt.

## **Setup**

1. **Clone Repo to your remote environment**

   ```
   git clone git@github.com:kirinmurphy/traefik_vps.git .
   ```

2. **Environment Variables**  
   <br>
   Add `.env` file to repo root in your production environment.

   ```
   # REQUIRED
   SSL_CERTIFICATION_EMAIL=some.email@address.com
   ```

3. **Makefile Commands**

   - `make up`: Starts the production Traefik service in the background.
   - `make down`: Stops the service.
   - `make restart`: Restarts the service.

## **Connecting an Application**

1. **Create the shared external network.**

   ```
   docker network create web
   ```

2. **Add application to the network.** Connect to the web network from your application's docker compose.

   ```yml
   services:
     my-app:
       image: my-app:latest
       networks:
         - web

   networks:
     web:
       external: true
   ```

3. **Add Traefik labels to your application service.** These define how to route traffic to your app.

   ```yml
   services:
     my-app:
       image: my-app:latest
       networks:
         - web
       labels:
         - "traefik.enable=true"
         - "traefik.http.routers.my-app.rule=Host(`your-domain.com`)"
         - "traefik.http.routers.my-app.entrypoints=websecure"
         - "traefik.http.routers.my-app.tls.certresolver=myresolver"
   ```

## **Security & Observability**

### Access Logging
JSON-formatted access logs are written to `/var/log/traefik/access.log` (volume-mounted from the host for fail2ban integration). All standard request fields (client IP, method, path, status, duration, TLS version) are kept. Request headers are dropped by default to avoid logging cookies and auth tokens, with selective exceptions for `User-Agent`, `Content-Type`, `X-Forwarded-For`, and `X-Real-Ip`.

### Security Headers
Applied globally via the `security-headers` middleware:
- **Strict-Transport-Security** — HTTPS-only for 2 years, including subdomains, with preload
- **X-Content-Type-Options: nosniff** — prevents MIME-type sniffing
- **X-Frame-Options: DENY** — blocks iframe embedding (clickjacking protection)
- **Referrer-Policy: strict-origin-when-cross-origin** — limits referrer data to external sites
- **X-XSS-Protection: "0"** — disables legacy XSS auditor (deprecated, itself exploitable)
- **Permissions-Policy** — blocks camera, microphone, and geolocation APIs

### Cross-Origin Isolation (opt-in)
Available via the `cross-origin-isolation` middleware but **not applied globally** — services opt in via Docker labels since these headers can break OAuth popups, external CDN resources, and cross-origin window interactions.
- **Cross-Origin-Opener-Policy: same-origin** — isolates browsing context from cross-origin popups
- **Cross-Origin-Resource-Policy: same-site** — prevents cross-origin resource reads (allows subdomains)

To attach, add to your service's Docker labels:
```yml
labels:
  - "traefik.http.routers.my-app.middlewares=cross-origin-isolation@file"
```

### Rate Limiting
100 requests/second sustained with bursts up to 150 per client. Returns `429 Too Many Requests` when exceeded.

### In-Flight Request Limiting
Caps concurrent connections at 100 per source IP. Complements rate limiting by catching slow-connection exhaustion (slowloris-style) attacks.

### Intentionally Excluded
- **CSP** — handled by Helmet at the app level; inherently app-specific
- **Request ID** — no native Traefik v3 support without plugins
- **Buffering middleware** — container runs `read_only: true`, disk spill would fail
- **ForwardedHeaders config** — default (`insecure: false`) is correct since Traefik is the edge proxy

## **CI Workflows**

- **Test (ci-test.yml)**: Creates a temporary test environment and verifies that HTTPS routing works correctly with a sample Nginx service.
- **Production (ci-prod-check.yml)**: start the Traefik container with the production `docker-compose.production.yml` file and checks its health status.
