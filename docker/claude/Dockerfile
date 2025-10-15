FROM alpine

RUN apk add --update npm

RUN npm install -g @anthropic-ai/claude-code

WORKDIR /srv

CMD ["claude"]
