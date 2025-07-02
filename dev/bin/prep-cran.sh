#!/usr/bin/env bash

curr_dir=$(pwd)
if [ "$(basename "$curr_dir")" != "solareclipser" ]; then
  printf "%s\n" "ERROR: Must be ran from the solareclipser directory."
  exit 1
fi

git_curr_branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$git_curr_branch" != "cran" ]; then
  printf "%s\n" "ERROR: Must be on the 'cran' branch to run this script."
  exit 1
fi


#dat_dir="dev/opt/prep-cran"
#if [ ! -d "$dat_dir" ]; then
#  mkdir -p "$dat_dir" || exit 1
#fi

vig="vignettes"
desc="DESCRIPTION"
rm -r "$vig" || exit 1

# update the Date field in DESCRIPTION
sed -i "s/^Date: .*/Date: $(date +'%Y-%m-%d')/" "$desc" || exit 1
# remove lines with knitr, rmarkdown, VignetteBuilder from the DESCRIPTION file
sed -i '/^Suggests:.*knitr/d' "$desc" || exit 1
sed -i '/^Suggests:.*rmarkdown/d' "$desc" || exit 1
sed -i '/^VignetteBuilder: /d' "$desc" || exit 1

#git_curr_head_hash=$(git rev-parse HEAD)
#cp -ra "$vig" "${dat_dir:?}/${vig}.${git_curr_head_hash:?}"   || exit 1
#cp -ra "$desc" "${dat_dir:?}/${desc}.${git_curr_head_hash:?}" || exit 1
