#!/bin/zsh
##? dus -- Directory size sorted
function dus() {
  du -sh * 2>/dev/null | sort -h
}
