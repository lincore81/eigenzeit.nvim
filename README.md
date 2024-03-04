# Eigenzeit - An automatic work logger for neovim

<div align="center">
<pre>
    Terrible timesheets,
    I automate the pain away,
    My mind is at ease.
</pre>

<img src="./docs/buddha-round-480.png" alt="" width="240"/>
</div>


## Use case

You might want to use this plugin if:
- You have strong incentive to track your work time.
- The idea of an unautomated menial tasks keeps you up at night.
- You want to be able to type `:Eigenzeit work feb` and get a report you can send to someone who cares.
- You find existing solutions too well-maintained and user-friendly.

## Installation & Setup
Please refer to your plugin manager's documentation if necessary. 
Here's a snippet for packer:

```lua
use {
    'lincore81/eigenzeit',
    config = function()
        require('eigenzeit').setup{
            -- snip --
        }
    end
}
```

By default, Eigenzeit will log three things:
- When you open a buffer (and which path)
- When you switch git branches (and which branch)
- How long you pound on the keyboard - and by extension, how long you're idle.

Assuming you don't equally care about everything you did in the editor, you can
define a set of tags (aka categories) that work should be sorted into. 
This does not alter the log, but it turns the log into a meaningful report.

Here's an example:

```lua
require('eigenzeit').setup{
    tags = {
        { "BE", condition = {"file-path", pattern = "projects/backend"}, consume=true },
        { "FE", condition = {"file-path", pattern = "projects/frontend"}, consume=true },
        { "Project: $1", condition = {"file-path", pattern = "projects/([%w_-]+)"} },
    },
}
```

And here's the whole reason why I wrote this:

```lua
require('eigenzeit').setup{
    tags = {
        { "$1", condition = {"git-branch", pattern = "(JIRA-%d+)"} },
    },
}
```

- Tags are tested in order. by default all matching tags are applied. To prevent this, you can add `consume = true` to a tag. 
- Right now there are only two conditions available, but you can create your own (see 'Customisation').

### Options
You can pass the following options to the setup function:

```lua
require('eigenzeit').setup{
    tags = { 
        -- snip -- 
    },
    options = { 
        -- SHOWING DEFAULT VALUES --

        -- Right now there's only one log file, but this will change later.
        log_dir = "$PLUGIN_DATA/logs",

        -- Best to keep this on unless you have good reason to be paranoid.
        -- There will be a command to delete untagged entries once I got around to it.
        log_untagged = true, 

        -- If not empty, any activity outside of these paths will be ignored.
        -- Expects a lua table of glob pattern strings.
        allowed_paths = {},

        -- Any activity inside these paths will be ignored.
        -- Can be used together with allowed_paths.
        -- Expects a lua table of glob pattern strings.
        disallowed_paths = {},
    }
}
```


## Customisation
Besides the builtin functionality, you can add your own events and matchers.

### Events
Events are simple tables created by autocmds and similar sources. They
should contain the following data:

```lua
{
    name = "moonphase",
    value = "crescent", -- optional, will be matched against the condition pattern/regex
    version = 1, -- v1 is implicit, may be useful if you introduce breaking changes
    foo = 42 -- you can add additional fields for matching/logging if needed
}
```
The event should be passed to the plugin via `require('eigenzeit').put_event(event)`.

### Event matchers
As the name implies, these functions determine if an event matches a rule.
Eigenzeit provides a default matcher that matches the event value against a
rule's condition pattern. If you need more complex logic, you can roll your
own. Please note that the output should be deterministic and wholly based on
the given inputs. Otherwise, retroactive application of changed rulesets may not
work as expected.

The matcher should be added to the setup function like so:

```lua
require('eigenzeit').setup({
    matchers = {
        moonphase = {
            -- for version 1, index should be made explicit if you need to
            -- handle multiple versions
            function(event, condition)
                -- default implementation if no custom matcher is provided:
                local shouldMatchValue = condition.value or condition.pattern
                return shouldMatchValue and event.value:match(condition.pattern) 
            end,
        }
    }
})
```

## Planned features (in no particular order)
- Manual tagging, push/pop tags
- Multiple conditions per tag with AND/OR
- use multiple log files. e.g. one per month/quarter
- caching/bookmarking of log data
- better query commands


## Etyomology
- ***Yay, it's German!***
- **Lit.:** 'own time', 'innate time'
- **Context:** mainly relativity theory, also philosophy, psychology/sociology
- **Why though?** Zeitraum was taken, I'm German and my boyfriend is a physicist `¯\_(ツ)_/¯`


## Scratchpad - ignore me

### Effectful parts
- Effectful code resides in init.lua
    - initial loading of the log
    - periodic saving of the log
        - configurable
        - I'd prefer 30 second intervals
        - only write if necessary, obviously
    - user commands
    - autocmds
    - other event sources

### How to detect git branch change?
https://www.reddit.com/r/neovim/comments/uz3ofs/heres_a_function_to_grab_the_name_of_the_current/


### Query syntax

```
 :Ez today
 :Ez yesterday
 :Ez feb
 :Ez 2024
 :Ez tues
 :Ez week -- this week
 :Ez month -- this month
 :Ez year -- this year
 :Ez 2023-12-10 to 2024-03-03
 :Ez 2023-12-10:10:00 to 2023-03-03:10:00
```



