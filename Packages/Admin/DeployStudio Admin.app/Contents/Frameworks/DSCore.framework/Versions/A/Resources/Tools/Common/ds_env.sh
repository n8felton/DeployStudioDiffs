#!/bin/sh

set | grep '^DS_' | sed s/^/export\ /

exit 0
