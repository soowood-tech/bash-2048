#!/usr/bin/env bash
# ==============================================================================
#  BASH 2048 - Classic 2048 puzzle game with Advanced AI solver in pure Bash
# ==============================================================================

C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_BORDER="\033[38;5;110m"
C_TITLE="\033[38;5;222m"
C_SCORE="\033[38;5;220m"
C_RECORD="\033[38;5;214m"
C_BOT_ON="\033[38;5;208m"
C_BOT_OFF="\033[38;5;244m"

get_tile_color() {
    case "$1" in
        0)    echo -e "\033[48;5;238m\033[38;5;244m" ;;
        2)    echo -e "\033[48;5;253m\033[38;5;235m" ;;
        4)    echo -e "\033[48;5;229m\033[38;5;235m" ;;
        8)    echo -e "\033[48;5;215m\033[38;5;231m" ;;
        16)   echo -e "\033[48;5;209m\033[38;5;231m" ;;
        32)   echo -e "\033[48;5;203m\033[38;5;231m" ;;
        64)   echo -e "\033[48;5;196m\033[38;5;231m" ;;
        128)  echo -e "\033[48;5;227m\033[38;5;234m\033[1m" ;;
        256)  echo -e "\033[48;5;226m\033[38;5;234m\033[1m" ;;
        512)  echo -e "\033[48;5;220m\033[38;5;234m\033[1m" ;;
        1024) echo -e "\033[48;5;214m\033[38;5;231m\033[1m" ;;
        2048) echo -e "\033[48;5;46m\033[38;5;232m\033[1m" ;;
        *)    echo -e "\033[48;5;129m\033[38;5;231m\033[1m" ;;
    esac
}

SCORE_FILE="$HOME/.bash_2048_highscore"
HIGHSCORE=0
if [[ -f "$SCORE_FILE" ]]; then
    HIGHSCORE=$(cat "$SCORE_FILE" 2>/dev/null || echo 0)
fi

cleanup() {
    tput cnorm 2>/dev/null
    stty echo 2>/dev/null
    tput rmcup 2>/dev/null
    printf "${C_RESET}\n"
    exit 0
}
trap cleanup SIGINT SIGTERM EXIT

declare -a board=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
declare -a prev_board=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
prev_score=0
score=0
won=0
auto_mode=0

calc_layout() {
    local term_cols term_lines
    term_cols=$(tput cols 2>/dev/null || echo 80)
    term_lines=$(tput lines 2>/dev/null || echo 24)

    BOX_W=29
    BOX_H=13

    OFFSET_X=$(( (term_cols - BOX_W) / 2 ))
    if (( OFFSET_X < 0 )); then OFFSET_X=0; fi
    OFFSET_Y=$(( (term_lines - BOX_H - 3) / 2 ))
    if (( OFFSET_Y < 0 )); then OFFSET_Y=0; fi
}

move_to() {
    local x=$(( $1 + OFFSET_X ))
    local y=$(( $2 + OFFSET_Y ))
    tput cup "$y" "$x"
}

draw_header() {
    move_to 0 0
    printf "${C_TITLE}${C_BOLD}   🎮 2048 IN PURE BASH${C_RESET}       "
    move_to 0 1
    local mode_str="${C_BOT_OFF}[AI: OFF]${C_RESET}"
    if [[ $auto_mode -eq 1 ]]; then
        mode_str="${C_BOT_ON}${C_BOLD}[AI: ON (Auto)]${C_RESET}"
    fi
    printf " ${C_SCORE}Score: ${C_BOLD}%-5d${C_RESET} │ ${C_RECORD}Best: ${C_BOLD}%-5d${C_RESET} │ %b" "$score" "$HIGHSCORE" "$mode_str"
}

format_tile() {
    local val=$1
    local color
    color=$(get_tile_color "$val")
    if [[ $val -eq 0 ]]; then
        printf "%b      %b" "$color" "$C_RESET"
    else
        printf "%b%*s%-*s%b" "$color" $(( (6 + ${#val}) / 2 )) "$val" $(( 6 - (6 + ${#val}) / 2 )) "" "$C_RESET"
    fi
}

render_board() {
    draw_header

    local y_start=3
    move_to 0 $y_start
    printf "${C_BORDER}┌──────┬──────┬──────┬──────┐${C_RESET}"

    for r in 0 1 2 3; do
        move_to 0 $(( y_start + 1 + r * 2 ))
        printf "${C_BORDER}│${C_RESET}"
        for c in 0 1 2 3; do
            local idx=$(( r * 4 + c ))
            format_tile "${board[idx]}"
            printf "${C_BORDER}│${C_RESET}"
        done

        move_to 0 $(( y_start + 2 + r * 2 ))
        if [[ $r -lt 3 ]]; then
            printf "${C_BORDER}├──────┼──────┼──────┼──────┤${C_RESET}"
        else
            printf "${C_BORDER}└──────┴──────┴──────┴──────┘${C_RESET}"
        fi
    done

    move_to 0 $(( y_start + 10 ))
    printf " ${C_DIM}WASD/Arrows | TAB: AI | U: Undo | R: Reset | Q: Quit${C_RESET}"
}

spawn_tile() {
    local empty_indices=()
    for ((i=0; i<16; i++)); do
        if [[ ${board[i]} -eq 0 ]]; then
            empty_indices+=($i)
        fi
    done

    if [[ ${#empty_indices[@]} -eq 0 ]]; then
        return
    fi

    local rand_idx=$(( RANDOM % ${#empty_indices[@]} ))
    local target_slot=${empty_indices[rand_idx]}

    if (( RANDOM % 10 == 0 )); then
        board[target_slot]=4
    else
        board[target_slot]=2
    fi
}

save_undo_state() {
    for ((i=0; i<16; i++)); do
        prev_board[i]=${board[i]}
    done
    prev_score=$score
}

restore_undo_state() {
    for ((i=0; i<16; i++)); do
        board[i]=${prev_board[i]}
    done
    score=$prev_score
}

slide_and_merge() {
    local -n _ref_line=$1
    local non_zero=()

    for val in "${_ref_line[@]}"; do
        if [[ $val -ne 0 ]]; then
            non_zero+=($val)
        fi
    done

    local merged=()
    local i=0
    local len=${#non_zero[@]}

    while (( i < len )); do
        if (( i + 1 < len )) && [[ ${non_zero[i]} -eq ${non_zero[i+1]} ]]; then
            local sum=$(( non_zero[i] * 2 ))
            merged+=($sum)
            score=$((score + sum))
            if [[ $sum -eq 2048 && $won -eq 0 ]]; then
                won=1
            fi
            i=$((i + 2))
        else
            merged+=(${non_zero[i]})
            i=$((i + 1))
        fi
    done

    while (( ${#merged[@]} < 4 )); do
        merged+=(0)
    done

    for ((j=0; j<4; j++)); do
        _ref_line[j]=${merged[j]}
    done
}

move_left() {
    save_undo_state
    local moved=0
    for r in 0 1 2 3; do
        local line=("${board[r*4]}" "${board[r*4+1]}" "${board[r*4+2]}" "${board[r*4+3]}")
        local orig=("${line[@]}")
        slide_and_merge line
        for c in 0 1 2 3; do
            board[r*4+c]=${line[c]}
            if [[ ${orig[c]} -ne ${line[c]} ]]; then moved=1; fi
        done
    done
    return $moved
}

move_right() {
    save_undo_state
    local moved=0
    for r in 0 1 2 3; do
        local line=("${board[r*4+3]}" "${board[r*4+2]}" "${board[r*4+1]}" "${board[r*4]}")
        local orig=("${line[@]}")
        slide_and_merge line
        for c in 0 1 2 3; do
            board[r*4+3-c]=${line[c]}
            if [[ ${orig[c]} -ne ${line[c]} ]]; then moved=1; fi
        done
    done
    return $moved
}

move_up() {
    save_undo_state
    local moved=0
    for c in 0 1 2 3; do
        local line=("${board[c]}" "${board[4+c]}" "${board[8+c]}" "${board[12+c]}")
        local orig=("${line[@]}")
        slide_and_merge line
        for r in 0 1 2 3; do
            board[r*4+c]=${line[r]}
            if [[ ${orig[r]} -ne ${line[r]} ]]; then moved=1; fi
        done
    done
    return $moved
}

move_down() {
    save_undo_state
    local moved=0
    for c in 0 1 2 3; do
        local line=("${board[12+c]}" "${board[8+c]}" "${board[4+c]}" "${board[c]}")
        local orig=("${line[@]}")
        slide_and_merge line
        for r in 0 1 2 3; do
            board[(3-r)*4+c]=${line[r]}
            if [[ ${orig[r]} -ne ${line[r]} ]]; then moved=1; fi
        done
    done
    return $moved
}

has_moves() {
    for ((i=0; i<16; i++)); do
        if [[ ${board[i]} -eq 0 ]]; then return 0; fi
    done
    for r in 0 1 2 3; do
        for c in 0 1 2 3; do
            local val=${board[r*4+c]}
            if (( c < 3 )) && [[ $val -eq ${board[r*4+c+1]} ]]; then return 0; fi
            if (( r < 3 )) && [[ $val -eq ${board[(r+1)*4+c]} ]]; then return 0; fi
        done
    done
    return 1
}

# ==============================================================================
#  ADVANCED HEURISTIC AI SOLVER
# ==============================================================================
# Snake-shaped weighting matrix concentrating largest tiles at bottom-left:
#  Row 0:   [ 1,      2,     4,     8   ]
#  Row 1:   [ 128,   64,    32,    16   ]
#  Row 2:   [ 256,  512,  1024,  2048   ]
#  Row 3:   [ 65536, 32768, 16384, 8192 ]
declare -a AI_WEIGHTS=(
    1     2     4     8
  128    64    32    16
  256   512  1024  2048
65536 32768 16384  8192
)

eval_board() {
    local score_val=0
    local empty_cnt=0

    for ((idx=0; idx<16; idx++)); do
        local v=${board[idx]}
        if [[ $v -eq 0 ]]; then
            empty_cnt=$((empty_cnt + 1))
        else
            score_val=$((score_val + v * AI_WEIGHTS[idx]))
        fi
    done

    # High bonus for keeping open space
    score_val=$((score_val + empty_cnt * 50000))
    echo $score_val
}

ai_step() {
    local backup_board=("${board[@]}")
    local backup_score=$score
    local best_move=""
    local best_eval=-999999999

    # Test all 4 directions in order: Down, Left, Right, Up
    for dir in "down" "left" "right" "up"; do
        # Restore board
        for ((i=0; i<16; i++)); do board[i]=${backup_board[i]}; done
        score=$backup_score

        local moved=0
        case "$dir" in
            "down")  move_down; moved=$? ;;
            "left")  move_left; moved=$? ;;
            "right") move_right; moved=$? ;;
            "up")    move_up; moved=$? ;;
        esac

        if [[ $moved -eq 1 ]]; then
            local ev
            ev=$(eval_board)
            if (( ev > best_eval )); then
                best_eval=$ev
                best_move=$dir
            fi
        fi
    done

    # Restore real state
    for ((i=0; i<16; i++)); do board[i]=${backup_board[i]}; done
    score=$backup_score

    # Execute best move
    if [[ -n "$best_move" ]]; then
        case "$best_move" in
            "down")  move_down ;;
            "left")  move_left ;;
            "right") move_right ;;
            "up")    move_up ;;
        esac
        spawn_tile
    fi
}

init_game() {
    local keep_auto=${1:-0}
    calc_layout
    board=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
    score=0
    won=0
    auto_mode=$keep_auto
    spawn_tile
    spawn_tile
    save_undo_state
    clear
    render_board
}

main() {
    tput smcup 2>/dev/null
    tput civis 2>/dev/null
    stty -echo 2>/dev/null

    init_game 0

    while true; do
        if [[ $score -gt $HIGHSCORE ]]; then
            HIGHSCORE=$score
            echo "$HIGHSCORE" > "$SCORE_FILE"
        fi

        render_board

        # Check Game Over
        if ! has_moves; then
            if [[ $auto_mode -eq 1 ]]; then
                move_to 0 $(( OFFSET_Y + 14 ))
                printf "  ${C_BOT_ON}${C_BOLD}🤖 AI GAME OVER! Restarting in 1s...${C_RESET} \n"
                # Brief sleep, responsive to Q
                for ((w=0; w<10; w++)); do
                    IFS= read -rsn1 -t 0.1 k
                    if [[ "$k" =~ [qQйЙ] ]]; then cleanup; fi
                done
                init_game 1
                continue
            else
                move_to 0 $(( OFFSET_Y + 14 ))
                printf "   ${C_SCORE}${C_BOLD}💀 GAME OVER! [R] Restart, [Q] Quit${C_RESET}   \n"
                while true; do
                    IFS= read -rsn1 k
                    case "$k" in
                        [rRкК]) init_game 0; break ;;
                        [qQйЙ]) cleanup ;;
                    esac
                done
                continue
            fi
        fi

        # Input or AI step
        local key=""
        local timeout=0.15
        if [[ $auto_mode -eq 1 ]]; then
            timeout=0.08
        fi

        IFS= read -rsn1 -t "$timeout" key

        if [[ "$key" == $'\e' ]]; then
            IFS= read -rsn2 -t 0.05 extra
            key+="$extra"
        fi

        if [[ $auto_mode -eq 1 && -z "$key" ]]; then
            ai_step
            continue
        fi

        local moved=0
        case "$key" in
            [wWцЦ]|$'\e[A'|$'\eOA')
                auto_mode=0
                move_up; moved=$? ;;
            [sSыЫ]|$'\e[B'|$'\eOB')
                auto_mode=0
                move_down; moved=$? ;;
            [aAфФ]|$'\e[D'|$'\eOD')
                auto_mode=0
                move_left; moved=$? ;;
            [dDвВ]|$'\e[C'|$'\eOC')
                auto_mode=0
                move_right; moved=$? ;;
            [uUгГ])
                auto_mode=0
                restore_undo_state ;;
            $'\t'|[tTеЕ])
                auto_mode=$((1 - auto_mode)) ;;
            [rRкК])
                init_game $auto_mode ;;
            [qQйЙ])
                cleanup ;;
        esac

        if [[ $moved -eq 1 ]]; then
            spawn_tile
        fi
    done
}

main
