#!/bin/bash
if [ ! -d $GOROOT/golang.org/x ];
    mkdir -p $GOROOT/golang.org/x
fi

cd $GOROOT/golang.org/x && git clone https://github.com/golang/tools.git tools
