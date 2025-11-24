# Human-readable size, trying to mimic `ls -lh` style:
#  - bare number for < 1024
#  - up to 3 digits + unit (K/M/G/...) for larger, max 4 chars total
human_size() {
  local bytes=$1
  local units=("" "K" "M" "G" "T" "P" "E")
  local i=0

  # < 1024: just the number, up to 4 digits
  if (( bytes < 1024 )); then
    printf '%d' "$bytes"
    return
  fi

  # Find a unit such that bytes / (1024^i) < 1024
  local unit_scale=1
  local next_scale
  while (( i < ${#units[@]} - 1 )); do
    next_scale=$(( unit_scale * 1024 ))
    if (( bytes < next_scale )); then
      break
    fi
    unit_scale=$next_scale
    (( i++ ))
  done

  # Now bytes / unit_scale is in [1, 1024)
  # Compute value * 10 to allow one decimal place, with rounding.
  # val10 = round(10 * bytes / unit_scale)
  local val10=$(( (bytes * 10 + unit_scale/2) / unit_scale ))

  local suffix=${units[i]}

  if (( val10 < 100 )); then
    # < 10.0 → show X.Y (3 chars) + unit (1 char) = 4 chars total
    local int=$(( val10 / 10 ))
    local frac=$(( val10 % 10 ))
    printf '%d.%d%s' "$int" "$frac" "$suffix"
  else
    # >= 10.0 → integer only
    local val=$(( (val10 + 5) / 10 ))   # round to nearest integer

    # If rounding pushed us to 1000+, bump unit once more if possible
    if (( val >= 1000 && i < ${#units[@]} - 1 )); then
      (( i++ ))
      suffix=${units[i]}
      unit_scale=$(( unit_scale * 1024 ))
      val=$(( (bytes + unit_scale/2) / unit_scale ))
    fi

    # Now val should be in [1, 999], so val+suffix fits in <=4 chars
    printf '%d%s' "$val" "$suffix"
  fi
}

usage_lstimes() {
  cat <<EOF
Usage: ${FUNCNAME[0]/usage_/} [--modified|--accessed|--changed|--created|--size] [PATH...]

List files with extended timestamps.

Time-sort options (last one wins if multiple are given):
  --modified   Sort by modification time (like: ls -t)
  --accessed   Sort by access time       (like: ls -tu)
  --changed    Sort by status change     (like: ls -tc)
  --created    Sort by birth/creation    (like: ls --time=birth -t, if supported)
  --size       Sort by file size         (like: ls -S)

If no PATH is given, '.' is used.
EOF
}

lstimes() {

  local -a ls_sort_opts=()   # extra flags to pass to ls for sorting
  local -a paths=()
  local arg

  while [[ $# -gt 0 ]]; do
    arg=$1
    case "$arg" in
      --modified)
        ls_sort_opts=(-t)
        shift
        ;;
      --accessed)
        ls_sort_opts=(-t -u)
        shift
        ;;
      --changed)
        ls_sort_opts=(-t -c)
        shift
        ;;
      --created)
        # May not be supported by all ls implementations; on GNU coreutils it's common.
        ls_sort_opts=(--time=birth -t)
        shift
        ;;
      --size)
        ls_sort_opts=(-S)
        shift
        ;;
      -h|--help)
        usage_lstimes
        return 0
        ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do
          paths+=("$1")
          shift
        done
        ;;
      -*)
        printf 'lstimes: unknown option: %s\n' "$arg" >&2
        usage_lstimes >&2
        return 1
        ;;
      *)
        paths+=("$arg")
        shift
        ;;
    esac
  done

  # If no paths were given, behave like "ls ."
  if ((${#paths[@]} == 0)); then
    paths=(*)
  fi

  # 1) Get the file list in "ls" order, with directories first.
  local -a files
  mapfile -t files < <(
    ls --group-directories-first -1 -d --color=never --quoting-style=literal \
      "${ls_sort_opts[@]}" -- "${paths[@]}"
  )

  # If nothing, exit
  ((${#files[@]} == 0)) && return 0

  # Decide whether to use color
  local use_color=auto
  local ls_color_flag

  if [[ $use_color == auto ]]; then
    if [[ -t 1 && $TERM != "dumb" ]]; then
      ls_color_flag='--color=always'
    else
      ls_color_flag='--color=never'
    fi
  else
    ls_color_flag='--color=never'
  fi

  # 2) Get the colored names for all files in one go
  local -a colored_fnames
  mapfile -t colored_fnames < <(
    ls --group-directories-first -d "${ls_color_flag}" --quoting-style=literal \
      "${ls_sort_opts[@]}" -- "${files[@]}"
  )

  # 3) Get stat output for all files in one go (same order)
  local -a stats
  mapfile -t stats < <(
    stat --printf="%A|%h|%U|%G|%s|%.19w|%.19x|%.19y|%.19z\n" -- "${files[@]}"
  )

  # Print header row
  local line_fmt="%-10s %1s %-8s %-6s %4s %-19s %-19s %-19s %-19s %s\n"
  printf "${line_fmt}" \
    "" "" "" "" "" \
    "Created" "Accessed" "Modified" "Changed" ""

  local idx fmetadata ts
  local -a array output
  for idx in "${!files[@]}"; do

    fmetadata=${stats[idx]}
    IFS='|' read -r -a array <<< "${fmetadata}"

    output=()
    output[0]=${array[0]}
    output[1]=${array[1]}
    output[2]=${array[2]}
    output[3]=${array[3]}

    ## Human-readable size
    #output[4]=$(numfmt --to=iec "${array[4]}")
    output[4]=$(human_size "${array[4]}")

    for i in 5 6 7 8; do
      ts="${array[$i]}"
      if [[ $ts == "-" ]]; then
        # Unknown birth time (%w) is "-"
        output[$i]="-"
      else
        # "YYYY-MM-DD  HH:MM:SS" -> "YYYY-MM-DDTHH:MM:SS"
        output[$i]=${ts/ /T}
      fi
    done

    ## Use precomputed colored name
    output[9]="${colored_fnames[idx]}"

    printf "${line_fmt}" \
      "${output[0]}" \
      "${output[1]}" \
      "${output[2]}" \
      "${output[3]}" \
      "${output[4]}" \
      "${output[5]}" \
      "${output[6]}" \
      "${output[7]}" \
      "${output[8]}" \
      "${output[9]}"

  done
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  lstimes "$@"
fi