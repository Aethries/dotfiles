#!/usr/bin/env bash

link_file() {
	local source="$1"
	local target="$2"

	mkdir -p "$(dirname "$target")"

	if [[ -L "$target" ]]; then
		if [[ "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
			return
		fi

		rm "$target"
	elif [[ -e "$target" ]]; then
		mv "$target" "$target.backup"
	fi

	ln -s "$source" "$target"
	echo " $target -> $source"
}

link_dir() {
	local source="$1"
	local target="$2"

	mkdir -p "$(dirname "$target")"

	if [[ -L "$target" ]]; then
		if [[ "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
			return
		fi

		rm "$target"
	elif [[ -d "$target"  ]]; then
		mv "$target" "$target.backup"
	fi

	ln -s "$source" "$target"
	echo " $target -> $source"
}
