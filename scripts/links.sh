#!/usr/bin/env bash

link_file() {
	local source="$1"
	local target="$2"

	if [[ ! -e "$source" && ! -L "$source" ]]; then
		echo "Error: source file does not exist: $source" >&2
		return 1
	fi

	mkdir -p "$(dirname "$target")"

	if [[ -L "$target" ]]; then
		if [[ -e "$target" ]] && [[ "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
			return 0
		fi
		rm -f "$target"
	elif [[ -e "$target" ]]; then
		local backup="$target.backup"
		if [[ -e "$backup" || -L "$backup" ]]; then
			local timestamp
			timestamp="$(date +%Y%m%d%H%M%S)"
			backup="$target.backup.$timestamp"
			local counter=1
			while [[ -e "$backup" || -L "$backup" ]]; do
				backup="$target.backup.${timestamp}_$counter"
				counter=$((counter + 1))
			done
		fi
		mv "$target" "$backup"
	fi

	if ! ln -s "$source" "$target"; then
		echo "Error: failed to symlink $source to $target" >&2
		if [[ -n "${backup:-}" && -e "$backup" ]]; then
			mv "$backup" "$target"
		fi
		return 1
	fi
	echo " $target -> $source"
}

link_dir() {
	local source="$1"
	local target="$2"

	if [[ ! -d "$source" ]]; then
		echo "Error: source directory does not exist: $source" >&2
		return 1
	fi

	mkdir -p "$(dirname "$target")"

	if [[ -L "$target" ]]; then
		if [[ -e "$target" ]] && [[ "$(readlink -f "$target")" == "$(readlink -f "$source")" ]]; then
			return 0
		fi
		rm -f "$target"
	elif [[ -e "$target" ]]; then
		local backup="$target.backup"
		if [[ -e "$backup" || -L "$backup" ]]; then
			local timestamp
			timestamp="$(date +%Y%m%d%H%M%S)"
			backup="$target.backup.$timestamp"
			local counter=1
			while [[ -e "$backup" || -L "$backup" ]]; do
				backup="$target.backup.${timestamp}_$counter"
				counter=$((counter + 1))
			done
		fi
		mv "$target" "$backup"
	fi

	if ! ln -s "$source" "$target"; then
		echo "Error: failed to symlink $source to $target" >&2
		if [[ -n "${backup:-}" && -e "$backup" ]]; then
			mv "$backup" "$target"
		fi
		return 1
	fi
	echo " $target -> $source"
}
