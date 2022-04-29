#!/bin/bash

for filename in tps/*.tps; do
    TexturePacker "$filename"
done
