server {
      listen 80;   
		  server_name localhost;
      root ${cargo_root}/dist;
      access_log  /var/log/nginx/cargo.access.log;
      error_log  /var/log/nginx/cargo.error.log;

        # gzip manifests
        gzip on;
        gzip_types application/vnd.apple.mpegurl;

        # file handle caching / aio
 proxy_cache off;
        open_file_cache max=1000 inactive=5m;
        open_file_cache_valid    2m;
        open_file_cache_min_uses 1;
        open_file_cache_errors   on;
        # aio on;
 location ^~ /account/ {
            proxy_pass http://127.0.0.1:8001;
            proxy_set_header Host $http_host;
            proxy_read_timeout 600s;
            proxy_http_version 1.1;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header Http_user_agent $http_user_agent;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            #proxy_cache_bypass $http_upgrade;
        }
        location / {
     try_files $uri $uri/ /index.html;
        }
 
        location ^~ /static/ {
              
            # root ${cargo_root}/priv;
        }

        location /favicon.ico {
            root   ${cargo_root}/static;
            access_log off;
            expires max;
        }
}

