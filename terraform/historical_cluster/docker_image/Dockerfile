
FROM --platform=linux/amd64 victoriametrics/vmrestore:v1.95.1  as builder1
FROM --platform=linux/amd64 victoriametrics/vmstorage:v1.95.1-cluster as builder2
#FROM --platform=linux/amd64 victoriametrics/vmselect:v1.95.1-cluster as builder3

FROM --platform=linux/amd64 alpine:3.16
COPY --from=builder1 /vmrestore-prod /vmrestore-prod
COPY --from=builder2 /vmstorage-prod /vmstorage-prod
#COPY --from=builder3 /vmselect-prod /vmselect-prod

ADD daily.sh /daily.sh

WORKDIR /
