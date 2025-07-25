#!/usr/bin/env bash
#
#  Part of https://github.com/jaclu/ish-fstool
#
#  License: MIT
#
#  Set nav key workaround for tmux
#  For scripted usage, give this the desired navkey as $1
#
#   1 Creates a tmux config snippet that can be sourced from local tmux
#     This is done by the default /etc/skel/.tmux.conf
#
#   2 Defines the nav key used, so in more advanced personalized usage
#     scenarios one can use env variables & SendKeys informing remote
#     hosts connected to via ssh that this session is run from iSH and
#     should be set up accordingly
#

clear_nav_key_usage() {
    rm -f "$f_tmux_nav_key"
    rm -f "$f_tmux_nav_key_handling"
}

tmux_mod_arrow() {
    mod="$1"

    case $mod in

    ctrl) t_mod="C" ;;
    shift) t_mod="S" ;;
    alt) t_mod="M" ;;

    *)
        error_msg "arrow_mod - param must be shift/ctrl"
        ;;
    esac

    echo "$mod" >"$f_tmux_nav_key"

    {
        echo "bind -n  ${t_mod}-Up     send-keys PageUp"
        echo "bind -n  ${t_mod}-Down   send-keys PageDown"
        echo "bind -n  ${t_mod}-Left   send-keys Home"
        echo "bind -n  ${t_mod}-Right  send-keys End"
    } >"$f_tmux_nav_key_handling"
}

tmux_esc_prefix() {
    if [[ "$sequence" = " " ]]; then
        echo "Do not use a nav-key work-arround"
        return
    fi

    #
    #  At least Esc must be converted from octal to special char
    #  for older tmux versions. doesn't hurt on newer
    #
    # sequence="$(echo $1 | sed 's/\\033/\\e/g')"
    sequence="${1//\\033/\\e}"

    echo "Escape prefixing will be mapped to: $sequence"
    {
        echo
        echo "#  For this to work, escape-time needs to be zero, or at least pretty low"
        echo "set -s escape-time 0"
        echo

        echo "#"
        echo "#  Using Esc prefix for nav keys"
        echo "#"
        echo "set -s user-keys[200]  \"$sequence\"" # escPrefix
        echo "bind -N \"Switch to -T escPrefix\" -n User200 switch-client -T escPrefix"
        echo
        echo "bind -T escPrefix  Down     send PageDown"
        echo "bind -T escPrefix  Up       send PageUp"
        echo "bind -T escPrefix  Left     send Home"
        echo "bind -T escPrefix  Right    send End"
        echo
        echo "# Double tap for actual Esc"
        echo "bind -T escPrefix  User200  send Escape"
    } >"$f_tmux_nav_key_handling"
    echo "$sequence" >"$f_tmux_nav_key"
}

add_to_sequence() {
    new_char="$1"
    if [[ -z "$new_char" ]]; then
        echo "ERROR: add_to_sequence() - no param"
    fi
    if [[ ! "$new_char" =~ [[:print:]] ]]; then
        #  Use three digit octal notation for non printables
        octal="$(printf "%o" "'$new_char'")"
        if [[ "$octal" -lt 100 ]]; then
            new_char="\\0$octal"
        else
            new_char="\\$octal"
        fi
    fi
    sequence="$sequence$new_char"
}

capture_keypress() {
    # Set terminal settings to raw mode
    stty raw -echo

    # Capture a single character
    char=$(dd bs=1 count=1 2>/dev/null)
    add_to_sequence "$char"

    # Check if more characters were generated
    IFS= read -rsn1 -t 0.1 peek_char
    while [[ -n "$peek_char" ]]; do
        char=$peek_char
        add_to_sequence "$char"
        IFS= read -rsn1 -t 0.1 peek_char
    done

    # Restore terminal settings
    stty sane
}

select_esc_key() {
    text="
This is a workaround to map Escape + arrows to the nav keys.
Be aware that the drawback of using this is that in order to generate Escape
inside tmux, you need to hit Esc twice.
If this outweighs the benefit of having the additional navigation keys
only you can decide.

If you want to enable this feature, hit the key you would use as Esc on your
keyboard. If you do not want to use this feature, hit space

In most cases, if you have selected 'External Keyboard - Backtick -> Escape'
This key would actually generate Esc, but this is not always the case.
For example the keyboard identified in BT settings as 'Yoozon 3.0 Keyboard'
generates (octal) \\302\\247 for the key, even with the Backtickk setting.

For such keyboards, this will also enable the intended key to generate Escape
in the first place inside tmux.
"
    if [[ -n "$1" ]]; then
        sequence="$1"
    else
        echo "$text"
        capture_keypress
    fi
    tmux_esc_prefix "$sequence"
}

select_nav_key_type() {
    text="
Chose how Nav-Keys (PageUp/PageDown & Home/End) are handled

Select modifier:
0 - Do not use a nav-key work-arround
1 - Escape prefix, then arrows, actual Escape requires Escape double tap
2 - <prefix> arrows - pane navigation is done vim-style: <prefix> hjkl

Esc as prefix then an arrow key, freeing up <prefix> arrow for pane navigation
    tradeoff: to trigger an Esc you need to double tap the Esc key.

<prefix> then arrow key, freeing up Esc to be a direct key.
    tradeoff: pane navigation is done vim-style: <prefix> hjkl

Not handled by this - in that case this is left to be configured manually.

"
    if [[ -n "$1" ]]; then
        selection="$1"
    else
        echo "$text"
        read -r selection
    fi

    case "$selection" in

    0)
        echo "Do not use a nav-key work-arround"
        ;;

    1)
        echo "Use Escape as arrow prefix for nav-keys"
        select_esc_key
        ;;
    2)
        echo "Use <prefix> arrow for nav-keys"
        select_esc_key
        ;;
    3)
        echo "Use Shift-Arrows for nav-keys"
        tmux_mod_arrow "shift"
        ;;
    4)
        echo "Use Ctrl-Arrows for nav-keys"
        tmux_mod_arrow "ctrl"
        ;;
    5)
        echo "Use Alt-Arrows for nav-keys"
        tmux_mod_arrow "alt"
        ;;
    *)
        echo "*****   Invalid selection   *****"
        sleep 1
        select_nav_key_type
        ;;
    esac
}

#===============================================================
#
#   Main
#
#===============================================================

# shellcheck source=/dev/null
. /usr/local/lib/ift-utils.sh

#
#  If a nav-key is defined, this file will contain a tmux config snippet
#  that the default .tmux.conf (/etc/skel/.tmux.conf) will source
#
f_tmux_nav_key_handling="/etc/opt/ift/tmux_nav_key_handling"
#
#  This is not used directly by ish-fstools, it just indicates the current nav-key
#  It can be used to inform remote nodes about iSH nav-key handling.
#  For more details check Docs/NavKey.md
#
f_tmux_nav_key="/etc/opt/ift/tmux_nav_key"

clear_nav_key_usage

text="
Since most iOS keyboards do not have dedicated PageUp, PageDn, Home and End
keys, inside tmux this can be solved by using work-arrounds.
Outside tmux, this setting will have no effect.

This setting can be changed at any time by running /usr/local/bin/nav-keys.sh
And will take effect next time you start tmux.
"

#
#  If $1 is defined, assume scripted usage, only mention what was selected
#
[[ -z "$1" ]] && echo "$text"

select_esc_key "$1"

select_nav_key_type "$1"

if [[ -z "$1" ]] && pgrep tmux >/dev/null; then
    echo
    echo "You need to restart tmux in order for this to take effect."
fi
