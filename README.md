# Zeitraum - Automatic work tracker and allocater

> en: time range
> lit: time space


## The purpose of Zeitraum
I need to create a monthly report on how much time I spent on jira tickets. I
am terrible at time tracking (and I hate it!), so I want my computer to do it
for me.


## Project objectives in order of importance
1. Write a neovim plugin because why not.
2. Write a neovim plugin that keeps track of what I'm working on and for how long and can create a nice report for me.


## Why not an existing solution?
See objective number 1.


## How should it work
- Ideally, Zeitraum would consist of a server and client, where the latter is a neovim plugin.
- This allows the implementation of different clients and standalone use.
- Any keypress is considered to indicate that work is being done
- The directory and branch being worked in tell Zr what is being worked on.
- Users can specify filters to define which directories and branches should be tracked
- E. g. a pattern like '!~/projects/personal/*` would ignore all work being done in that directory.


## How does timing work
- When the user presses any key, 5 minutes of work (configurable) are added to the records.
- If another keypress comes in less time, the previous 'work packet's length is reduced to the time delta.
- In other words, we assume that up to 5 minutes of not pressing a key is still work (reading code, drinking water etc.)

## How is work allocated
- Each piece of work gets one (or more?) tags assigned
- Tags have rules 

### Example:
```lua
config = {
    {
        "work email",
        match_dir = "~/.email/work/*",
    },
    {
        {"jira-all", "jira-%d"},
        match_dir = "~/projects/work/*",
        match_git_branch = "JIRA-(%d)",
    },
}
```

- Rules are evaluated from top to bottom
- If a rule matches, the work will be "consumed" and associated with the tag(s).
- If no rule matches, the work is dropped and not stored.

## How is work stored
- Ideally clients should report every single keystroke, but report several seconds of work
- The server will regularly chunk consecutive work packets and store the result
- If server and/or client get interrupted, only a few seconds should be lost.

### Data example:

```
["work_email"] = {
    { from=46172896, to=446738634 },
    { from=46172896, to=446738634 },
}
```


## Rough server CLI
zeitraum pause | resume | start | stop 
zeitraum add [wd] {seconds} (adds a work packet in the given directory)
zeitraum log [tag] [seconds] (manually add time)
zeitraum unlog [tag] [seconds] (manually remove time)
zeitraum report [tag] {range}

