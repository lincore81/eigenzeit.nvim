# Eigenzeit - An automatic work logger for neovim

<div align="center">
<pre>
    Terrible timesheets,
    I automate the pain away,
    My mind is at ease.
</pre>

<img src="./docs/buddha-round-480.png" width="240" alt="A happy Buddha is enjoying neovim on his laptop, while sitting on a tree trunk.">
</div>


***Not ready for use yet, critical features are missing.***


## Use case
You might want to use this plugin if:
- You have a strong incentive to track your work time.
- The idea of an unautomated menial tasks keeps you up at night.
- You want to be able to type `:Eigenzeit work feb` and get a report you can send to someone who cares.
- You don't mind battle-testing a plugin that's still in its infancy. (But it's written to be audit-proof, if that's any consolation.)


## Installation & Basic Setup
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

Calling setup is required.
Without any extra configuration, Eigenzeit will log your work and changes to the
file path as well as the current git branch.

You can get a report by calling `:Eigenzeit`, which will just list the total
hours worked this month. 


### Tagging Rules
Tags are used to categorise your work in reports. The underlying data is not
affected at all, so you can try out different rulesets without losing any
information.

Here's an example:

```lua
require('eigenzeit').setup{
    tags = {
        { "good times", 
            condition = {"file_path", pattern = "projects/green-pastures"}, 
        },
        { "$1", 
            group = "bad times", 
            condition = {
                {"git_branch", pattern = "(JIRA[-_ ]%d+.*)$"},
                {"file_path", pattern = "projects/crusty-socks"},
            },
            consume = true,
        },
    },
}
```

A few things to note:
- The `condition` field takes an event type and a pattern to match the event value against. There are 2 builtin events:
  - `file_path` - The value is the current absolute file path.
  - `git_branch` - The value is the current git branch.
- Multiple tags can be applied to the same piece of work, but Eigenzeit is smart enough to not double-count the time.
- Tag rules are applied in order of appearance.
- The `consume` flag is used to prevent further tags from being applied to the same piece of work (it doesn't really do anything here).
- Backreferences can be used to create 'dynamic' tags.
- You can `group` (dynamic) tags if you are interested in the total time spent on a group of tags.

Calling `:Eigenzeit` will now show a report like this:

```
March 2024 up to now:

 4h 41m - good times
27h 17m - bad times
          |  3h 21m - JIRA-1221-refactor-ui
          |  4h 55m - JIRA-1234-add-feature
          |  8h 39m - JIRA-1301-unbreak-ui
          | 10h 22m - JIRA-1378-remove-feature
----------------------------------------------
32h 02m                           Gaps: 3h 58m
```



### Options
You can pass the following options to the setup function:

```lua
require('eigenzeit').setup{
    tags = { 
        -- snip -- 
    },
    options = { 
        -- SHOWING DEFAULT VALUES --

        -- Used for reporting
        start_of_week = 1, -- 1 = Sunday, 2 = Monday, ..., 6 = Friday, 7 = Saturday

        -- Right now there's only one log file, but this will change later.
        log_dir = "$PLUGIN_DATA/logs",

        -- If not empty, any activity outside of these paths will be ignored.
        -- Includes buffers without a file path.
        -- Expects a lua table of glob pattern strings.
        allowed_paths = {},

        -- Any activity inside these paths will be ignored.
        -- Can be used together with allowed_paths.
        -- Expects a lua table of glob pattern strings.
        disallowed_paths = {},
    }
}
```

## Usage

### Querying
You can call `:Eigenzeit` to get a report.

The syntax is `:Eigenzeit [tag1, tag2, ...] [range]`.

#### Range Syntax
Implicit range:
- `today`
- `yesterday`
- `this week`
- `last week`
- `this month`
- `last month`
- `this year`
- `last year`
- `2024-02-01`
- `feb(ruary)`
- `mon(day)`
- `2023`

Explicit range:
- `08:00 to 17:00` -- Today from 8am to 5pm, inclusive.
- `2024-02-01 to 2024-02-29` -- February 2024.
- `last feb to today` -- February of previous year up to now.
- `mon to now` -- This Monday up to now (now is a synonym of today).

Note:
- `this` is implied and can thus be omitted.
- Queries are case-insensitive.
- At the moment the following date/time formats are supported:
    - `YYYY-MM-DDTHH:MM(:SS)` (T, t, -, :, space are all valid separators)
    - `YYYY-MM-DD`
    - `HH:MM(:SS)` (24hrs)
- Support for American date formats will be added later if people care about it.
- The start of the week defaults to Sunday, you can change it in the setup options (see above).
- The default range is `this month`.


## Advanced Setup & Customisation
### Custom Effects
Effects are what I call autocmds, timers etc. that generate Eigenzeit events. 
To tell Eigenzeit when you want it to log something, you can call
`require("eigenzeit").dispatch(event)`.

An event should look like this:
```lua
{
    name = "user:battery",
    value = 0.7,        
    state = "charging",
}
```

A few things to note:
- "name" must be a string.
- "value" must be truthy. If you use anything other than a number or string, you will need to provide a custom matcher.
- Other fields are optional and can be used to provide additional context. They will be logged as well.
- Events are discarded if the value has not changed.


### Custom Event Matchers
Event matchers determine whether a tagging rule should be applied to an event.
Eigenzeit provides a default matcher that matches the event value against a
rule's condition pattern. If you need more complex logic, you can roll your
own. Please note that the output should be deterministic and wholly based on
the given inputs. Otherwise, retroactive application of changed rulesets may not
work as expected. 

The matcher should be added to the setup function like so:

```lua
require('eigenzeit').setup({
    matchers = {
        battery = {
            function(event, condition)
                -- default implementation:
                local shouldMatchValue = event.value or condition.pattern
                if not shouldMatchValue then return false end
                if type(event.value) == "number" then
                    return event.value == condition.pattern
                else
                    return event.value:match(condition.pattern) 
                end
            end,
        }
    }
})
```
If you want to add generic matchers, use the `default` key. They will be used if
no specific matcher is found for an event, but before the builtin matcher.

```lua
require('eigenzeit').setup({
    matchers = {
        default = {
            function(event, condition)
                -- snip --
            end,
        }
    }
})
```


## Etyomology
- ***Yay, it's German!***
- **Lit.:** 'own time', 'innate time'
- **Context:** mainly relativity theory, also philosophy, psychology/sociology
- **Why though?** Zeitraum was taken, I'm German and my boyfriend is a physicist `¯\_(ツ)_/¯`

