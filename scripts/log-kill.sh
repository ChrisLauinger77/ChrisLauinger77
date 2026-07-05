#!/bin/bash

cd /var/log/
find -name "*.gz" -delete
journalctl --vacuum-time=1d