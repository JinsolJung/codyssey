FROM nginx:stable-alpine
LABEL org.opencontainers.image.title="codyssey-workstation-lab"
ENV NGINX_PORT=8080
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY site/ /usr/share/nginx/html/
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 CMD wget -q -O /dev/null "http://127.0.0.1:${NGINX_PORT}/health" || exit 1
