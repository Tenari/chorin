# a command-line chore tracker

names of things should be unique to use this. this only supports using a gmail smpt server account (so make a gmail acct for use with this)

## install

`git clone` and `cd chorin` and then setup your `.env` file to look like:

```
---
:from: you@gmail.com
:pw: your password goes here
```
then, to enable your gmail acct to send the email:
[go here](https://myaccount.google.com/lesssecureapps)

and enable the less secure apps

## examples

- remind yourself how this dumb thing works again: `./autochore.rb help`
- create new user named Tom with an email address `./autochore.rb new user -n 'Tom' -e 'tommyodom.austin@gmail.com'`
- create new "Empty Sink" chore that should be done every 4 days, tagged for the house: `./autochore.rb new chore -t house -n 'Empty Sink' -f 4d`
- list unassigned (open) chores for the house tag: `./autochore.rb list chores open -t house`
- list assigned (ready) chores for the farm tag: `./autochore.rb list chores ready -t farm`
- assign a chore (by name) to a user (by name): `./autochore.rb assign 'Empty Sink' 'Tom'`
- send emails to all users with the chores they have past-due, due today, and due tomorrow: `./autochore.rb send`


