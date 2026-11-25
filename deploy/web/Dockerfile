# Variante A: fertigen Web-Build (Ordner ./site) in ein nginx-Image packen.
#   docker build -t chrono-web .
#   docker run -d -p 8080:80 --name chrono-web chrono-web
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY site/ /usr/share/nginx/html/
EXPOSE 80
