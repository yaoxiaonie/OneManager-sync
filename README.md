# OneManager-sync
OneManager-sync is a shell script that can clone file like github repo.
It is only suitable for OneManager-php's **renexmoe** theme.

# Feature
1.Using multithreading to clone.

2.Can restore the permission and symlink.

3.Can use header config.

## How to install
```
sudo apt install aria2 curl pv
git clone https://github.com/yaoxiaonie/OneManager-sync.git
```

### Example usage
1. ```cd OneManager-sync```
2. ```./sync.sh [YOUR URL]```
