#!/bin/sh
# shellcheck disable=SC2292 # needed when this is imported into bash script
#
# Copyright (c) 2026: Jacob.Lundqvist@gmail.com
#
# License: MIT
#
# Part of https://github.com/jaclu/helpful-scripts
#
#  common posix utils I use in my helpful-scripts, usable both for posix and bash
#
#  Variables that can be set before sourcing this
#
#  usu_ignore_ctrl_c - Set this to 1 if scrip-utils.sh should not handle Ctrl-C
#  app_name - will be set to basename "$0" if unset
#  usu_current_dbg_lvl - will be set to 0 if unset
#  usu_exit_func - Per default just before exit, even on errors runtime and date is printed
#  This can be overridden, by setting this in two ways, by setting it to "skip"
#  runtime/date will not be printed, by naming a supplied function, this will be
#  called instead,
#
#
# Suggestion how to source this
#
# load_utils() {
#     # location of helpful-scripts repo if not the typical
#     _d_usu_base="${1:-$HOME/git_repos/mine/helpful-scripts}"
#     _f_usu_utils="$_d_usu_base"/utils/script-utils.sh

#     # shellcheck source=utils/script-utils.sh disable=SC1091,SC2317
#     . "$_f_usu_utils" || {
#         printf '\n%s[%s] ERROR: Sourcing %s failed\n' "$0" "$$" "$_f_usu_utils" >&2
#         exit 1
#     }
# }
# call load_utils early on in your script
#

#---------------------------------------------------------------
#
#   Exit / Error handling
#
#---------------------------------------------------------------

usu_ctrl_c_pressed() {
    trap - INT # restore default behavior to let olint etc capture
    usu_ctrl_c_was_pressed=1
    # shellcheck disable=SC2154 # app_name defined in script-utils.sh
    lbl_1 "usu ${app_name}[$$] caught Ctrl-C, press it again to abort immediately."
}

usu_check_ctrl_c() {
    # exit program at predefined suitable moments
    [ "$usu_ctrl_c_was_pressed" -eq 1 ] && {
        lbl_1 "usu ${app_name}[$$] Handling ctrl-C"
        # cleanup tmp files and exit 3 for Ctl-C pressed
        script_utils_cleanup "$usu_exit_ctrl_c_pressed"
    }
}

script_utils_trap_handler() {
    # Since we got here via our own trap, it should be safe to disable
    # our own trap handling. Since err_msg wasn't called, assume no error exit
    dbg_msg "script_utils_trap_handler()" 1
    script_utils_cleanup 0
}

usu_default_exit_func() {
    display_app_run_time
    date
}

no_trap_exit() {
    # Call this instead of exit, to avoid risking triggering script_utils_trap_handler
    trap - EXIT
    exit_code="${1:-0}"
    dbg_msg "no_trap_exit() $exit_code" 4
    is_int "$exit_code" || {
        printf '\n\nERROR: no_trap_exit() called with exit code: %s\n' "$exit_code"
        exit "$usu_exit_not_int_exit_code"
    }
    #
    # The exit code is provided for reference, if the usu_exit_func does not exit,
    # it will happen here.
    #
    [ -n "$usu_exit_func" ] && $usu_exit_func "$exit_code"
    exit "$exit_code"
}

silent_exit() {
    # skip potential usu_exit_func, like after displaying help etc
    ex_code="${1:-0}"
    usu_exit_func=""

    dbg_msg "silent_exit() ex_code: $ex_code" 4
    no_trap_exit "$ex_code"
}

script_utils_cleanup() {
    #
    # Unless the default EXIT trap handler has been overridden, this will be called
    # automatically as script exits. If exit is wanted in the middle of a snippet,
    # it would be better to call this with exit code 0, to make it clear that
    # cleanup is requested, instead of just doing exit 0, but both do the same.
    #
    # If cleanup_custom() is defined, it will be called early on. If it is not defined,
    # the default is to display app run-time (if -s was given also print date).
    #
    # Next each remaining tmpfile is checked. If it has content, it is displayed
    # before being deleted. To avoid this tmpfile dump if tmpfiles are used,
    # define a cleanup_custom() where any remaining tmpfiles are cleared via
    # a call to tmp_file_remove.
    #
    # If exit code is > -1 this will end by calling no_trap_exit
    #
    _suc_no_custom=0
    while [ -n "$1" ]; do
        case "$1" in
            -s | --skip-custom) _suc_no_custom=1 ;; # err_msg has already called it
            *) break ;;
        esac
        shift
    done

    # echo "state of tmp logfile - script_utils_cleanup() start: $f_usu_log_file"
    # ls -l "$f_usu_log_file"
    # echo

    _suc_ex_code="$1"
    dbg_msg \
        "script_utils_cleanup() -s:$_suc_no_custom ex:$_suc_ex_code" 1

    #
    #  Recursion handling
    #
    [ -n "$usu_suc_allready_called" ] && {
        printf 'ERROR %s[%s] RECURSION script_utils_cleanup() - exiting now\n' \
            "$app_name" "$$" >&2
        no_trap_exit "$usu_exit_suc_recursion"
    }

    usu_suc_allready_called=1

    [ "$_suc_no_custom" = 0 ] && {
        if command -v cleanup_custom >/dev/null 2>&1; then
            #
            # Template explanation of cleanup_custom():
            #
            # This is is called from script-utils cleanup, or indirectly by err_msg,
            # so only do final tasks and potentially local cleanup here, don't exit!
            # $1 is the exit code that will be used, just for info, in case what happens
            # here depends on success/error exit
            #
            cleanup_custom "$_suc_ex_code"
        fi
    }

    # Remove all tmp files created by this script.
    # Two-pass approach: first pass notifies about all leftovers (read-only on index),
    # second pass deletes them (using safe_remove, which doesn't modify index).
    # Index will be discarded at the end, so intermediate states don't matter.
    if [ -s "$f_usu_tmp_file_index" ]; then
        echo # separator with previous content
        # PASS 1: Notify about all leftover tmpfiles and display their content
        _sc_file_num=0
        while IFS= read -r _sc_f || [ -n "$_sc_f" ]; do
            [ -n "$_sc_f" ] || continue

            _sc_file_num=$((_sc_file_num + 1))
            printf 'WARNING %s[%s]: script_utils_cleanup() - %s\n%s\n' \
                "$app_name" "$$" \
                "temp file #${_sc_file_num} not cleared by app:" \
                "$_sc_f" >&2
            if [ -s "$_sc_f" ]; then
                printf '=====   Displaying content   =====\n' >&2
                cat "$_sc_f" >&2
                # add LF only if content didn't end with one
                [ -z "$(tail -c 1 "$_sc_f")" ] || printf '\n' >&2
                printf -- '-----   end of tmp file   -----\n' >&2
            fi
        done <"$f_usu_tmp_file_index"

        # PASS 2: Delete leftover tmpfiles
        # (safe_remove exits on failure, but all notifications already displayed)
        printf '\n' >&2
        _sc_file_num=0
        while IFS= read -r _sc_f || [ -n "$_sc_f" ]; do
            [ -n "$_sc_f" ] || continue
            [ -f "$_sc_f" ] || continue

            _sc_file_num=$((_sc_file_num + 1))
            safe_remove "$_sc_f"
            printf 'leftover tmp file #%d removed\n' "$_sc_file_num" >&2
        done <"$f_usu_tmp_file_index"
        printf '\n' >&2
    fi
    safe_remove "$f_usu_tmp_file_index"

    # echo "state of tmp logfile post tmpfile erase: $f_usu_log_file"
    # ls -l "$f_usu_log_file"
    # echo

    #
    #  Handling exit, param is evaluated late, in order to not risk preventing
    #  tmpfile cleanup from happening
    #
    [ -n "$_suc_ex_code" ] || {
        _display_error "script_utils_cleanup() no exit-code param"
        no_trap_exit "$usu_exit_suc_no_exit_code"
    }
    is_int "$_suc_ex_code" || {
        _display_error "script_utils_cleanup() exit-code is not int: $_suc_ex_code"
        no_trap_exit "$usu_exit_not_int_exit_code"
    }
    [ "$_suc_ex_code" -gt -1 ] && no_trap_exit "$_suc_ex_code"

    # In case this was called without intention to exit, reset the recursion watch
    usu_suc_allready_called=""
}

err_msg() {
    #
    #  Display an error message, second optional param is exit code,
    #  defaulting to 1. If exit code is -1 this will not exit, just display
    #  the error message and continue.
    #  This will always display timestamp
    #
    _skip_custom=""

    while [ -n "$1" ]; do
        case "$1" in
            -s) _skip_custom="-s" ;;
            -*)
                echo
                echo "ERROR err_msg() invalid option: $1"
                no_trap_exit "$usu_exit_errmsg_invalid_option"
                ;;
            *) break ;;
        esac
        shift
    done
    _em_msg="$1"
    _em_exit_code="${2:-1}" # script_utils_cleanup will evaluate valid exit code
    _em_label="${3:-ERROR}"
    # is used  both by script_utils_cleanup and _display_error
    [ -z "$app_name" ] && app_name=$(basename "$0")

    dbg_msg "err_msg() -s:$_skip_custom ex: $_em_exit_code msg:$_em_msg" 9
    #
    #  Recursion handling
    #
    [ -z "$_em_in_progress" ] && _em_in_progress=0
    case "$_em_in_progress" in
        0) ;;
        1)
            # recursion during err_msg, display msg and abort
            _em_in_progress=2
            printf 'ERROR %s[%s] RECURSION err_msg() msg:%s\n' \
                "$app_name" "$$" "$_em_msg" >&2
            script_utils_cleanup "$usu_exit_errmsg_recursion"
            ;;
        *)
            # script_utils_cleanup is recursing back again, just abort
            printf 'ERROR %s[%s] RECURSION lvl:%s err_msg() msg:%s\n%s\n' \
                "$app_name" "$$" "$_em_in_progress" "$_em_msg" "Exiting now" >&2
            no_trap_exit "$usu_exit_errmsg_double_recursion"
            ;;
    esac
    if is_int "$_em_in_progress"; then
        _em_in_progress=$((_em_in_progress + 1))
    else
        _em_in_progress=1
    fi

    if [ -z "$usu_suc_allready_called" ]; then
        # Run it before displaying the error msg, in case it displays remaining
        # tmp files and they are long, but with no exit.
        # It will be run again at the end of this
        if [ -n "$_skip_custom" ]; then
            script_utils_cleanup --skip-custom -1
        else
            script_utils_cleanup -1
        fi
    else
        _abort_due_to_suc_recursion=1
    fi

    if [ -z "$_em_msg" ]; then
        _em_msg="err_msg() no message"
        _em_exit_code=31 # Ensure this is exited
    fi

    _display_error "$_em_msg" "$_em_label"

    [ -n "$_abort_due_to_suc_recursion" ] && {
        printf 'ERROR %s[%s] err_msg() exits due to script_utils_cleanup() recursion\n' \
            "$app_name" "$$" >&2
        no_trap_exit "$usu_exit_suc_recursion"
    }

    # if custom was desired it has already been run, so now it can safely be skipped
    script_utils_cleanup --skip-custom "$_em_exit_code"

    # In case this was called without intention to exit, reset the recursion watch
    _em_in_progress=0 # in case exit code was < 0
}

#---------------------------------------------------------------
#
#   Display msgs
#
#---------------------------------------------------------------

show_timestamp() {
    printf "%s" "$(date +'%F %T')"
}

_display_error() {
    # Actually display an error msg, should normally not be called by other code
    _dm_msg="$1"
    _dm_label="${2:-ERROR}"

    echo >&2
    log_it "${app_name}[$$] ${_dm_label}: $_dm_msg" -t # should always have timestamps
    echo >&2
}

log_it() {
    #
    #  prefix msg to display with any of the supported options
    #    -p | --pre-lf
    #    -n | --no-lf
    #    -r | --timestamp
    #
    #  if f_usu_log_file is defined, msg will also be appended there,
    #  log file will always us timestamp prefix
    #

    # option parsing
    _li_dbg_lvl=""
    _li_use_time_stamp=0
    _li_use_lf=1
    while [ -n "$1" ]; do
        is_int "$1" && { # assume its short notation for log_lvl
            _li_dbg_lvl="$1"
            shift
            continue
        }
        case "$1" in
            ---*) break ;; # dont parse any further opts
            -d | --dbg_level)
                _li_dbg_lvl="$2"
                shift # extra shift for $2
                ;;
            -p | --pre-lf) printf '\n' ;;
            -n | --no-lf) _li_use_lf=0 ;;
            -t | --timestamp) _li_use_time_stamp=1 ;;
            -*) err_msg "log_it() Unknown option: [$1]" "$usu_exit_log_it" ;;
            *) break ;; # no more options
        esac
        shift
    done

    _li_msg="$1"
    _t=""
    [ -z "$_li_msg" ] && err_msg "log_it() no param" "$usu_exit_log_it"
    [ -n "$_li_dbg_lvl" ] && {
        is_debug_lvl "$_li_dbg_lvl" || return
    }

    if [ "$_li_use_time_stamp" = 1 ] || [ "$usu_always_use_time_stamps" = 1 ]; then
        _t="[$(show_timestamp)] $_li_msg"
        _li_msg="$_t"
    fi
    if [ "$_li_use_lf" = 1 ]; then
        printf -- '%s\n' "$_li_msg" >&2
    else
        printf -- '%s' "$_li_msg" >&2
    fi

    [ -z "$f_usu_log_file" ] && return 0 # logfile not used
    case "$_li_msg" in
        *[![:space:]]*) ;; # more than white space - log it to file
        *) return 0 ;;     # only whitespace - skip logging it to file
    esac
    # Always use timestamp if printing to logfile
    [ -z "$_t" ] && _t="[$(show_timestamp)] $_li_msg"
    printf -- '%s\n' "$_t" >>"$f_usu_log_file"
}

lbl_1() {
    [ -z "$1" ] && err_msg "lbl_1() no param"
    _l1s="$1" # can't use _s due to multiple log_it calls and it overwrites _s
    shift
    log_it "${@}" " "
    log_it "${@}" "===  $_l1s  ==="
    log_it "${@}" " "
}

lbl_2() {
    [ -n "$1" ] || err_msg "lbl_2() no param"
    _s="$1"
    shift
    log_it "${@}" "---  $_s"
}

lbl_3() {
    [ -n "$1" ] || err_msg "lbl_3() no param"
    _s="$1"
    shift
    log_it "${@}" " --  $_s"
}

lbl_4() {
    [ -n "$1" ] || err_msg "lbl_4() no param"
    _s="$1"
    shift
    log_it "${@}" "  -  $_s"
}

lbl_5() {
    [ -n "$1" ] || err_msg "lbl_5() no param"
    _s="$1"
    shift
    log_it "${@}" "  .  $_s"
}

#---------------------------------------------------------------
#
#   Debugging
#
#   usu_current_dbg_lvl=0 means only dbg_msg without dbg_lvl 2nd param will be displayed
#
#---------------------------------------------------------------

dbg_msg() {
    #
    # set debug lvl with param 2, if not given, will always be displayed,
    # otherwise displayed if debug lvl <= usu_current_dbg_lvl
    # dbg_msg() does not support the log_it options --no-lf
    # timestamp will be printed if param 3 is -t or always_use_time_stamp() has
    # been called
    #
    [ -n "$1" ] || err_msg "dbg_msg() no param" "$usu_exit_debug"
    if [ -n "$2" ]; then
        _usu_this_dbg_lvl="$2"
    else
        _usu_this_dbg_lvl=0
    fi
    is_debug_lvl "$_usu_this_dbg_lvl" && log_it "DBG[$_usu_this_dbg_lvl]  $1" "$3"

}

set_debug_lvl() {
    _usu_new_dbg_lvl="$1"
    is_int "$_usu_new_dbg_lvl" || {
        _s="$_usu_new_dbg_lvl"
        _usu_new_dbg_lvl=9
        err_msg "set_debug_lvl() - non int param: $_s" "$usu_exit_debug"
    }
    usu_current_dbg_lvl="$_usu_new_dbg_lvl" # propagate it to any subshells
}

increase_debug_lvl() {
    usu_current_dbg_lvl=$((usu_current_dbg_lvl + 1))
}
decrease_debug_lvl() {
    [ "$usu_current_dbg_lvl" -gt 0 ] && usu_current_dbg_lvl=$((usu_current_dbg_lvl - 1))
}

is_debug_lvl() {
    _id_lvl="$1"
    is_int "$_id_lvl" || {
        err_msg "is_debug_lvl() non-int param: $_id_lvl" "$usu_exit_debug"
    }
    [ "$_id_lvl" -le "$usu_current_dbg_lvl" ]
}

#---------------------------------------------------------------
#
#   Handling tmp / log files
#
#---------------------------------------------------------------

always_use_time_stamp() {
    usu_always_use_time_stamps=1
}

tmp_file_create() {
    #
    # Generic tmp file that can be used by scripts.
    #
    # if param is provided, tmp file name will be assigned to the variable name $1
    # otherwisse f_usu_tmp will be used. This allows for multiple tmp files if needed,
    # just call this func multiple times with different variable names.
    #
    # Any calls to err_msg() will display current content of and then remove it.
    # It will also be autoremoved once script exits, unless some of the signals
    # monitored are overridden
    #

    #
    # Option parsing
    #
    _tfc_is_dir=false
    _tfc_forkless=false
    _tfc_variable=""
    while [ -n "$1" ]; do
        case "$1" in
            -d | --directory) _tfc_is_dir=true ;;
            -*) err_msg "tmp_file_create() Unknown option: $1" ;;
            *)
                _tfc_variable="$1"
                break
                ;;
        esac
        shift
    done

    if [ -n "$app_name" ]; then
        _tfc_template_label="$(basename "$app_name")"
    else
        _tfc_template_label="script-utils.sh"
    fi
    _tfc_template="${TMPDIR:-/tmp}/${_tfc_template_label}.tmp-XXXXXX"

    if $_tfc_is_dir; then
        _tfc_tmp_file=$(mktemp -d "$_tfc_template") || {
            err_msg "mktemp -d $_tfc_template failed for: _tfc_tmp_file"
        }
        dbg_msg "tmp_file_create() new tmp directory: $_tfc_tmp_file" 3
    else
        _tfc_tmp_file=$(mktemp "$_tfc_template") || {
            err_msg "mktemp $_tfc_template failed for: _tfc_tmp_file"
        }
        dbg_msg "tmp_file_create() new tmp file: $_tfc_tmp_file" 3
    fi
    echo "$_tfc_tmp_file" >>"$f_usu_tmp_file_index" || {
        err_msg "tmp_file_create() - Failed to update usu_tmp_file_index" \
            "$usu_exit_tmp_file_issue"
    }
    if [ -n "$_tfc_variable" ]; then
        eval "$_tfc_variable=\"\$_tfc_tmp_file\"" # variable assignment tmpfile
    else
        printf '%s' "$_tfc_tmp_file" # classical for and print approach
    fi
}

tmp_file_add() {
    #
    # Add named file to list of tmpfiles. This ensures it will be removed at
    # exit of program, and made an embarrassment if not properly deleted
    #
    _tfa_tmp_file="$1"
    [ -n "$_tfa_tmp_file" ] || err_msg "tmp_file_add() no param"
    dbg_msg "tmp_file_add() fname:[$_tfa_tmp_file]" 9

    [ -n "$2" ] && err_msg "tmp_file_add() no longer supports 2 params"
    echo "$_tfa_tmp_file" >>"$f_usu_tmp_file_index" || {
        err_msg "tmp_file_add() - Failed to update usu_tmp_file_index" \
            "$usu_exit_tmp_file_issue"
    }
}

tmp_file_remove() {
    # If tmp_file is a folder, delete it and it's content
    # _tfr_tmp="${1:-$f_usu_tmp}"
    _tfr_tmp="${1:-$f_usu_tmp}"
    [ -z "$_tfr_tmp" ] && err_msg "tmp_file_remove() called with no param"
    dbg_msg "tmp_file_remove() $_tfr_tmp" 9

    # [ -f "$_tfr_tmp" ] || err_msg "tmp_file_remove() no such file: $_tfr_tmp"
    was_sys_path "$_tfr_tmp" && {
        err_msg "tmp_file_remove() called with system path: $_tfr_tmp"
    }
    safe_remove --remove-dir "$_tfr_tmp"

    # update list of current tmp files, removing the one just removed
    content=$(grep -vxF -e "$_tfr_tmp" "$f_usu_tmp_file_index" 2>/dev/null)
    if [ -n "$content" ]; then
        printf '%s\n' "$content" >"$f_usu_tmp_file_index" || {
            err_msg "tmp_file_remove() - Failed to update usu_tmp_file_index" \
                "$usu_exit_tmp_file_issue"
        }
    else
        safe_remove "$f_usu_tmp_file_index"
    fi
}

use_log_file() {
    #
    # provide a log_file and if defined all msgs and errors will be appended there
    # after being printed to stderr. It is up to the caller to remove this logfile!
    #
    # [ -z "$1" ] && err_msg "Call to use_log_file() no param given"
    if [ -n "$1" ]; then
        f_usu_log_file="$1"
        _usu_tmp_file_as_log_file=0
        dbg_msg "use_log_file() $f_usu_log_file" 9
    else
        # no log file provided, will create a tmp file for logging

        tmp_file_create f_usu_log_file
        _usu_tmp_file_as_log_file=1 # make a note that this file should be deleted
        printf '%s\n' \
            '' \
            '************************************************************' \
            '*                                                          *' \
            '*   WARNING: use_log_file() called without a filename      *' \
            '*                                                          *' \
            '*   Log files are normally expected to be named.           *' \
            '*   A temporary log file has been created as a fallback.   *' \
            '*   Its contents will be displayed and the file removed    *' \
            '*   when the program exits.                                *' \
            '*                                                          *' \
            '*   Please check the caller for a missing or empty         *' \
            '*   filename argument.                                     *' \
            '*                                                          *' \
            '************************************************************' \
            '' \
            "logfile: $f_usu_log_file" >&2
    fi
}

cancel_log_file() {
    # Only remove the log file if a filename was provided.
    _clf_named_log_file="$1"
    f_usu_log_file="" # Stop logging output.

    dbg_msg "cancel_log_file() $_clf_named_log_file" 9
    [ -n "$_clf_named_log_file" ] && {
        # Remove the log file and, if it is a tracked tmpfile, remove it
        # from the list of active tmpfiles.
        tmp_file_remove "$_clf_named_log_file"
    }
}

#---------------------------------------------------------------
#
#   Timing
#
#---------------------------------------------------------------

select_safe_now_method() { # local usage by safe_now()
    #
    # Select and save the time method for future use.
    # Using milliseconds when possible
    #
    # Provides:
    #  usu_selected_safe_now_mthd
    #  usu_t_max_digits
    #
    [ -n "$usu_selected_safe_now_mthd" ] && {
        err_msg "Recursive call to: select_safe_now_method"
    }
    # log_it "select_safe_now_method()"

    if is_linux || is_termux; then
        usu_t_max_digits=9
        usu_selected_safe_now_mthd="date" # date supports high precision
    elif command -v gdate >/dev/null 2>&1; then
        usu_t_max_digits=6
        usu_selected_safe_now_mthd="gdate" # GNU date found
    elif command -v perl >/dev/null 2>&1; then
        # fallback via Perl, can display higher prec, but takes a long
        # and hugely variable time to run
        usu_t_max_digits=3
        usu_selected_safe_now_mthd="perl"
    else
        usu_t_max_digits=0
        usu_selected_safe_now_mthd="date" # last resort, seconds-only
    fi
}

safe_now() {
    #
    #  Sets t_usu_now to the current timestamp. If a variable name is given,
    #  it will be assigned the same value directly (no subshell).
    #
    #  Provides:
    #      t_usu_now - current unix time
    #
    _sn_var_name="$1"

    case "$usu_selected_safe_now_mthd" in
        date) t_usu_now="$(date +%s.%9N)" ;;
        gdate) t_usu_now="$(gdate +%s.%6N)" ;;
        perl)

            # shellcheck disable=SC2034 # t_usu_now is used below in eval
            t_usu_now="$(perl -MTime::HiRes=time -e \
                'printf "%.3f\n", time()*100000 /100000')"
            ;;
        *)
            select_safe_now_method

            # to prevent infinite recursion, eunsure a valid timing method is now selected
            case "$usu_selected_safe_now_mthd" in
                date | gdate | perl) ;;
                *) err_msg "safe_now($_sn_var_name) - failed to select a timing method" ;;
            esac

            safe_now "$_sn_var_name"
            return
            ;;
    esac
    [ -n "$_sn_var_name" ] && {
        # if variable name provided set it to t_usu_now
        eval "$_sn_var_name=\"\$t_usu_now\""
    }
}

time_span() { # display_menu() / check_speed_cutoff()
    #
    # Calculates a time span in seconds compared to param
    # Additional params:
    #   milli      - calculate time span in milli-seconds
    #   nodisplay  - do not display elapsed time
    #
    # Provides: t_usu_time_span
    #
    _usu_display_result=0
    _usu_decimals=0
    while [ -n "$1" ]; do
        case "$1" in
            --display) _usu_display_result=1 ;;
            --milli) _usu_decimals=3 ;;
            --micro) _usu_decimals=6 ;;
            --nano) _usu_decimals=9 ;;
            --digits)
                _usu_decimals="$2"
                shift # get rid of param
                ;;
            *) break ;;
        esac
        shift
    done
    _ts_start="$1"
    [ -n "$_ts_start" ] || err_msg "time_span() - no start time provided"
    is_int "$_usu_decimals" || {
        err_msg "time_span() - decimals requested not a number: $_usu_decimals"
    }
    safe_now _usu_t_now
    [ "$_usu_decimals" -gt "$usu_t_max_digits" ] && {
        _s="time_span() - requested $_usu_decimals digite,"
        _s="$_s only $usu_t_max_digits available, will be rounded down"
        dbg_msg "$_s"
        _usu_decimals="$usu_t_max_digits"
    }
    if [ "$_usu_decimals" = 0 ]; then
        _usu_t1=$(int_part "$_ts_start")
        _usu_t2=$(date +%s)
        # simple seconds notation
        t_usu_time_span=$((_usu_t2 - _usu_t1))
    else
        # shellcheck disable=SC2154 # _usu_t_now assigned by safe_now
        t_usu_time_span=$(awk \
            -v t2="$_usu_t_now" \
            -v t1="$_ts_start" \
            -v decimals="$_usu_decimals" '
                BEGIN {
                    factor = 10 ^ decimals
                    print int((t2 - t1) * factor) / factor
                }')
    fi
    [ "$_usu_display_result" = 1 ] && {
        _ts_int=${t_usu_time_span%%.*}
        if [ "$_ts_int" -gt 59 ]; then
            display_time_elapsed "$_ts_int"
        else
            printf '%ss\n' "$t_usu_time_span"
        fi
    }
}

display_time_elapsed() {
    #
    # Duration param is assumed to be a timespan in seconds
    # This displays  a time duration in human readable form
    #
    # under a minute- display it as 34s
    #
    # a minute or more - display it in hh:mm:ss notation 0:03:21
    #
    # t1="$(date +%s)"
    # do something...
    # t_duration="$(($(date +%s) - t1))"
    # s_time_elapsed=$(display_time_elapsed "$t_duration)")
    #
    _dte_duration="${1:-$t_usu_time_span}"

    if [ "$_dte_duration" -gt 59 ]; then
        _dte_hours=$((_dte_duration / 3600))
        _dte_days=$((_dte_hours / 24))
        _dte_minutes=$(((_dte_duration % 3600) / 60))
        _dte_seconds=$((_dte_duration - _dte_hours * 3600 - _dte_minutes * 60))
        if [ "$_dte_days" -gt 0 ]; then
            printf "%d days %02d:%02d:%02d" \
                "$_dte_days" \
                "$_dte_hours" \
                "$_dte_minutes" \
                "$_dte_seconds"
        else
            printf '%02d:%02d:%02d' "$_dte_hours" "$_dte_minutes" "$_dte_seconds"
        fi
    else
        printf '%ss' "$_dte_duration"
    fi
}

display_app_run_time() {
    # additional notices can be added in $1
    _dart_msg="${1:-}" # linting safe way to handle "optional" parameters...
    # _dart_te=$(display_time_elapsed "$(($(date +%s) - t_start))")
    echo
    log_it "Time elapsed: $(
        time_span --display --digits 1 "$t_start"
    ) - $app_name $_dart_msg"
}

#---------------------------------------------------------------
#
#   File checks
#
#---------------------------------------------------------------

was_sys_path() {
    case "$1" in
        /tmp/* | /var/tmp/* | "$TMPDIR"/*) return 1 ;; # tmp files can always be removed

        /bin | /bin/* | /boot | /boot/* | /dev | /dev/* | /etc | /etc/* | /home | \
            "$HOME" | /lib | /lib/* | /lib64 | /lib64/* | /lost+found | /lost+found/* | \
            /media | /media/* | /mnt | /mnt/* | /opt | /opt/* | /proc | /proc/* | \
            /root | /run | /run/* | /sbin | /sbin/* | /sys | /sys/* | /tmp | \
            /usr | /usr/* | /var | /var/* | /Users) return 0 ;;
        *) ;;
    esac
    return 1
}

_do_safe_remove() {
    _dsr_item=$1
    # dbg_msg "_do_safe_remove($_dsr_item)" 4

    [ -z "$_dsr_item" ] && err_msg "safe_remove() missing path" "$usu_exit_safe_remove"

    $_sr_check_sys_path && was_sys_path "$_dsr_item" && {
        err_msg "Refusing to remove a sys-path: $_dsr_item" "$usu_exit_safe_remove"
    }

    if [ -d "$_dsr_item" ]; then
        mount | grep "$_dsr_item" && {
            err_msg "safe_remove() this is a mount point: $_dsr_item" \
                "$usu_exit_safe_remove"
        }
        if $_sr_remove_dir; then
            rm -rf -- "$_dsr_item" || {
                err_msg "Failed to remove directory: $_dsr_item" \
                    "$usu_exit_safe_remove"
            }
            $_sr_display_removal && dbg_msg "Removed directory: $_dsr_item" 1
        else
            # shellcheck disable=SC2115 # _dsr_item is already checked for being empty
            rm -rf -- "$_dsr_item"/* "$_dsr_item"/.??* 2>/dev/null || {
                err_msg "Failed to clear directory: $_dsr_item" "$usu_exit_safe_remove"
            }
            $_sr_display_removal && dbg_msg "Cleared directory: $_dsr_item" 1
        fi
        return
    fi

    if [ -f "$_dsr_item" ] || [ -L "$_dsr_item" ]; then
        rm -- "$_dsr_item" || {
            err_msg "Failed to remove file: $_dsr_item" "$usu_exit_safe_remove"
        }
        $_sr_display_removal && dbg_msg "safe_remove() Removed file: $_dsr_item" 1
    else
        err_msg "Refusing to remove non-file: $_dsr_item" "$usu_exit_safe_remove"
    fi
}

safe_remove() {
    #
    # if item is a folder it is just cleared, unless it is prefixed with --remove-dir
    # then the entie folder is removed
    # Anything containing a sys path is rejected, unless --ignore-sys-path is supplied
    #
    # After options are parsed
    #   $1  File/folder name to be removed
    #   $2  exit code on error (default: 1)
    #

    #
    # Option parsing
    #
    _sr_check_sys_path=true
    _sr_display_removal=true
    _sr_remove_dir=false

    while [ -n "$1" ]; do
        case "$1" in
            --ignore-sys-path) _sr_check_sys_path=false ;;
            -s | --silent) _sr_display_removal=false ;;
            -r | --remove-dir) _sr_remove_dir=true ;;
            -*) err_msg "safe_remove() Unknown option: $1" "$usu_exit_safe_remove" ;;
            *) break ;;
        esac
        shift
    done

    for f; do
        [ -e "$f" ] || {
            if [ -L "$f" ]; then
                dbg_msg "safe_remove() Will process dead symlink: $f" 1
            else
                dbg_msg "safe_remove() Ignored absent file [$f]" 2
                continue
            fi
        }
        _do_safe_remove "$f"
    done
    return 0
}

source_it() {
    # Fails if $2 was provided and that variable was not defined as non-empty
    _si_f="$1"
    _si_inspect_variable="$2"

    # dbg_msg "[$0] source_it($_si_f)"
    [ "$app_name_full_path" = "$_si_f" ] && {
        echo
        echo "WARNING: Attempt at self sourcing ignored: $_si_f"
        echo
    }

    # shellcheck source=/dev/null # filename is dynamic
    . "$_si_f"
    [ -n "$_si_inspect_variable" ] && {
        # if variable name provided verify that it has content
        eval "_v2=\"\${$_si_inspect_variable}\""
        [ -n "$_v2" ] || {
            err_msg "Sourcing $_si_f didn't define variable: $_si_inspect_variable"
        }
    }
}

#---------------------------------------------------------------
#
#   conversions
#
#---------------------------------------------------------------

int_part() {
    # Prints int part of a numerical param
    _usu_f="$1"
    [ -z "$_usu_f" ] && err_msg "int_part() - no param"
    printf '%s\n' "${_usu_f%%.*}"
}

#---------------------------------------------------------------
#
#   boolean checks
#
#---------------------------------------------------------------

is_int() {
    case $1 in
        '') return 1 ;;        # reject empty string
        -) return 1 ;;         # reject lone '-'
        -*) set -- "${1#-}" ;; # strip leading '-'
        *) : ;;                # default no-op
    esac

    case $1 in
        *[!0-9]*) return 1 ;; # reject any non-digit chars
        *) return 0 ;;        # accept pure digits
    esac
}

is_yaml_true() {
    _yt_s="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    # [ -z "$_yt_s" ] && err_msg "is_yaml_true() no param"
    _yt_result=1 # default
    case "$_yt_s" in
        1 | yes | true) _yt_result=0 ;;
        *) ;;
    esac
    return "$_yt_result"
}

#
# Platform type identifiers
#
is_linux() { # returns true if kernel is Linux, very broad check
    [ "$(uname -s)" = "Linux" ]
}

is_linux_native() { # Filters out chrooted and various Linux based derivates
    is_linux || return 1
    if is_ish || is_termux || is_android || is_chrooted; then
        return 1
    fi
    return 0
}

is_macos() {
    [ "$(uname -s)" = "Darwin" ]
}

is_android() {
    #  Only used to verify this_is_linux_native
    is_termux && return 1
    [ "$(uname -o)" = "Android" ]
}

is_ish() {
    [ -d /proc/ish ]
}

is_ish_aok() {
    is_ish && grep -qi ish-AOK /proc/version
    # return 0 # for devel and testing - fake this is aok
}

is_termux() {
    [ "$HOME" = /data/data/com.termux/files/home ]
}

is_chrooted() {
    # this quick and simple check doesn't work on ish
    # so lets pretend for now chroot does not happen on ish
    is_linux || return 1
    [ -f /proc/self/mountinfo ] || return 1
    ! grep -q " / / " /proc/self/mountinfo
}

#
# File System type identifiers
#
fs_is_alpine() {
    [ -f /etc/alpine-release ]
}

fs_is_debian() {
    { fs_is_ubuntu || fs_is_devuan; } && return 1
    [ -f /etc/debian_version ]
}

fs_is_devuan() {
    test -f /etc/devuan_version
}

fs_is_ubuntu() {
    grep -qs '^ID=ubuntu$' /etc/os-release
}

fs_is_gentoo() {
    [ -f /etc/gentoo-release ]
}

#
#  Mostly for development builds
#
is_chrooted_ish() {
    # Relies on /opt/AOK/tools/do_chroot.sh or similar creating/removing this
    # file inside the chrooted env when entering/leaving the chroot
    is_chrooted && [ -f /etc/opt/chrooted_ish ]
}

is_ish_abstract() {
    is_ish || is_chrooted_ish
}

#
# Other checks
#
is_musl_lib() {
    ldd /bin/sh 2>&1 | grep -qi musl
}

#===============================================================
#
#   Main
#
#===============================================================

# these must be done before local variables assignments,
# since some of them depend on variables defined by them
# read_config
# check_if_host_or_dest_fs

#
#  Optional params to be set before calling this:
#
# Defaults to show runtime and date, if nothing is desired set it to "skip"
# if custeom exit msg is desired set it to a function doing this
case "${usu_exit_func:-}" in
    "") usu_exit_func="usu_default_exit_func" ;;
    skip) usu_exit_func="" ;;
    *) ;; # already assigned

esac

#
#  Locations for various stuff
#
TMPDIR="${TMPDIR:-/tmp}"
TMPDIR="${TMPDIR%/}" # strip trailing slah, mostly for MacOS

app_name_full_path=$(realpath "$0")
[ -z "$app_name" ] && app_name=$(basename "$0")
t_start="$(date +%s)" # is used in display_app_run_time()

[ -z "$usu_current_dbg_lvl" ] && {
    # In case usu_current_dbg_lvl has been exported to the env, do not override it
    set_debug_lvl 0
}

usu_ctrl_c_was_pressed=0
usu_current_dbg_lvl=0
f_usu_tmp_file_index="$TMPDIR/$app_name-tmpfile-list-$$"

#
#  Internal exit codes
#
usu_exit_ctrl_c_pressed=3 # uses static 3 for Ctrl-C
usu_exit_not_int_exit_code=100
usu_exit_debug=101
usu_exit_safe_remove=102
usu_exit_log_it=103
usu_exit_tmp_file_issue=104
usu_exit_errmsg_invalid_option=105
usu_exit_errmsg_recursion=106
usu_exit_errmsg_double_recursion=107
usu_exit_suc_recursion=108
usu_exit_suc_no_exit_code=109

# Create traps in order to be able to kill of any tmp files
# this would normally run at the very start, so if the app sets its own
# traps, it will override this
trap 'script_utils_trap_handler' EXIT HUP TERM

[ -z "$usu_ignore_ctrl_c" ] && {
    dbg_msg "${app_name}[$$] usu handles ctrl-c" 1
    trap 'usu_ctrl_c_pressed' INT
}

# ensures the above doesn't indicate sourcing failed
return 0
