# **Traefik External Edge Router**

This repository provides a self-contained, lightweight edge proxy that simplifies managing and routing HTTPS traffic to your applications running in other Docker containers. This is especially useful for a VPS or a remote server where you need a single entry point to manage multiple applications.

### **Example Usage on a VPS**

Imagine you have more than one application that you want to use on the same website. Instead of manually configuring an Nginx server for each application and managing separate SSL certificates, you can use this repository as a single, central entry point for HTTPS and (in the future) other edge functions.

1. This Traefik stack runs on your VPS. It manages traffic on a public `web` network.
2. It listens on ports 80 and 443.
3. Your separate application containers are configured to join the same `web` network that Traefik is on.
4. You add labels to your application containers that tell Traefik where to route traffic. For example, a label could say "if the request is for blog.yourdomain.com, send it to this container."
5. Traefik automatically handles the SSL certificates for your domains (blog.yourdomain.com, portfolio.yourdomain.com) using Let's Encrypt.

## **Setup & Usage**

### **Clone Repo to your remote environment**

```
git clone git@github.com:kirinmurphy/traefik_vps.git .
```

### **Environment Variables**

Add `.env` file to repo root in your production environment.

```
# REQUIRED
SSL_CERTIFICATION_EMAIL=some.email@address.com
```

### **Makefile Commands**

- `make up`: Starts the production Traefik service in the background.
- `make down`: Stops the production Traefik service.

### **How to Connect an Application**

To connect an application from a separate Docker Compose deployment to this Traefik instance, you need to follow these steps:

1. **Ensure you have created the shared external network.**

   ```
   docker network create web
   ```

2. **Add your application to the network.** In your application's docker-compose.yml, add the web network to the networks section and set it as external.

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

3. **Add Traefik labels to your application service.** These labels tell Traefik how to route traffic to your app.

   ```yml
   services:
     my-app:
       image: my-app:latest
       labels:
         - "traefik.enable=true"
         - "traefik.http.routers.my-app.rule=Host(`your-domain.com`)"
         - "traefik.http.routers.my-app.entrypoints=websecure"
         - "traefik.http.routers.my-app.tls.certresolver=myresolver"
   ```

## **CI Workflows**

- **Test (ci.yml)**: This workflow validates the Traefik setup by running `test.sh`. This script creates a temporary test environment and verifies that HTTPS routing works correctly with a sample Nginx service.
- **Production (ci-prod-check.yml)**: This workflow ensures that the production configuration is valid. It attempts to start the Traefik container with the production `docker-compose.production.yml` file and checks its health status.
