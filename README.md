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

## **CI Workflows**

- **Test (ci-test.yml)**: Creates a temporary test environment and verifies that HTTPS routing works correctly with a sample Nginx service.
- **Production (ci-prod-check.yml)**: start the Traefik container with the production `docker-compose.production.yml` file and checks its health status.
