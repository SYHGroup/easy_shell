#!/bin/sh
NAMES=$(kubectl config get-contexts | awk '{print $(NF-3)}' | tail -n +2 | sort -u)
for NAME in $NAMES;do
kubectl config use-context $NAME
kubectl scale --replicas=1 deployment --all
done
