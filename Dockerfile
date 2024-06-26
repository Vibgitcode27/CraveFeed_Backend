FROM golang:alpine

WORKDIR /app

RUN apk add --no-cache postgresql-client

COPY go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o cravefeed_backend

RUN echo '#!/bin/sh' > wait-for-db.sh && \
    echo 'until pg_isready -h postgres -p 5432 -U postgres; do' >> wait-for-db.sh && \
    echo '  echo "Waiting for postgres..."' >> wait-for-db.sh && \
    echo '  sleep 2' >> wait-for-db.sh && \
    echo 'done' >> wait-for-db.sh && \
    echo 'echo "PostgreSQL started"' >> wait-for-db.sh && \
    echo 'exec "$@"' >> wait-for-db.sh && \
    chmod +x wait-for-db.sh

EXPOSE 3000

CMD ["./wait-for-db.sh", "sh", "-c", "go run github.com/steebchen/prisma-client-go migrate dev --name add --preview-feature --create-only && go run github.com/steebchen/prisma-client-go migrate deploy --preview-feature && ./cravefeed_backend"]