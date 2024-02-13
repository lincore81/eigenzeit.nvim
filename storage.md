# How to do storage

## Options
- sqlite3 (sqlite.lua)
- vim.json in vim.fn.stdpath('data') ++ '/zeitraum'

I'll go with json for now, because it's most likely easier to use. Will
consider sqlite later/if necessary.

## What to store
We store time ranges of uninterrupted work. An interruption is assumed after 5
minutes of inactivity.

We store unix timestamps, the friendly times are just for illustrative purposes:
```
{
    {from = 08:11, to = 08:22},
    {from = 08:24, to = 08:44},
    {from = 08:50, to = 09:05},
    {from = 09:32, to = 09:46},
    ...
}
```

We always add 5 minutes to the last timestamp received. It is assumed that code
reading, water sipping, messaging, going to the toilet etc. constitute work.

If the next packet arrives after 5 minutes (or whatever time we end up
chosing), we start a new range.

```
{
    {"event", at = 08:11, name = "change-file", target = "~/mail/748920364", tags = {"emails"}},
    {"work", from = 08:11, to = 08:22},
    {"work", from = 08:24, to = 08:44},
    {"work", from = 08:50, to = 09:05},
    {"event", at = 09:00, name = "user-set-exlusive-tag", target = "meeting", tags={"meeting"}},
    {"event", at = 09:31, name = "user-clear-exclusive-tag", target = "meeting"},
    {"event", at = 09:31, name = "git-checkout", target = "feat/jira-872-fix-the-thing", tags={"jira-872"}},
    {"work", from = 09:32, to = 09:46},
}
```

This is basically a log, which is probably good to have (verify stuff works as
expected, allow users to edit, recalculate everything on demand). We should
at some point also store accumulated data that is updated alongside so we don't
have to reduce the whole log anytime the user wants to know how long they've
been working on something.



