# Processing stuff

```lua
local config = {
    tags = {
        work = {meta = true}
    },
    patterns = {
        {dir = "~/mail/*", addtags = {"emails", "work"}},
        {dir = "~/projects/foo/*", ignore = true},
        {dir = "~/projects/*", addtags = {"work"}},
        {dir = "~/projects/*", gitbranch = "jira-(\d+)", addtags = {"jira-$1"}},
    }
}
```

```lua
local log = {
    {"event", at = "08:11", name = "change-file", target = "~/mail/748920364", tags = {"emails"}},
    {"work", from = "08:11", to = "08:22"},
    {"event", at = "08:24", name = "change-file", target = "~/mail/783478676", tags = {"emails"}},
    {"work", from = "08:24", to = "08:44"},
    {"work", from = "08:50", to = "09:05"},
    {"event", at = "09:00", name = "user-set-tags", target = {"work, "meetings"}, tags={"meetings"}},
    {"event", at = "09:31", name = "user-clear-tags", target = {"meetings"},
    {"event", at = "09:31", name = "git-checkout", target = "feat/jira-872-fix-the-thing", tags={"jira-872"}},
    {"work", from = "09:32", to = "09:46"},
}
```

```
:Zr jira-827
14 minutes
```

```
:Zr today
emails:     46m
meetings:   31m
jira-872:   14m
------------------
            1h31m

work:       1h31m
gaps:       8m 
------------------
            1h39m
```
