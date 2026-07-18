# LatLang
![Logo](/logo.png)

![Stars](https://img.shields.io/github/stars/JakeOJeff/lat?style=for-the-badge)
![Commits](https://img.shields.io/github/commit-activity/w/JakeOJeff/lat?style=for-the-badge)
![Downloads](https://img.shields.io/gem/dt/lat?style=for-the-badge)
![License](https://img.shields.io/github/license/JakeOJeff/lat?style=for-the-badge)

A **Language** which compiles to Lua, built for [LÖVE](https://love2d.org). Written in Ruby!

Syntax inspired by Lua, Ruby, Python and Java

## Requirements

- [Ruby](https://www.ruby-lang.org) 
- [LÖVE2D](https://love2d.org)

## Run without Installation [ For Reviewers ( Ruby and Love2d still required)]

### 1. Clone this repo

```bash
    git clone https://github.com/JakeOJeff/lat.git
    cd lat
```

### 2. Write your code in a .lat file

There is some example code in the examples/ folder which you can use.

### 3. Run the compiler against the lat file

```bash
    ruby .\compiler\compile.rb .\examples\main.lat
```

## Setup

### 1. Clone this repo

```bash
    git clone https://github.com/JakeOJeff/lat.git
    cd lat
```

### 2. Install it

#### Linux/MacOS (tbd)

```bash
    chmod +x install/install.sh
    ./install/install.sh
```

#### Windows

```bat
    install\install.bat
```

### Usage

```bash
    lat ^<file.lat^> # compile and run
    lat build # compile only
    lat run # compile last build
```

### Syntax

> Syntax guide coming soon. See [guide.md](guide.md) or the Wiki for now.

### Demo:
https://github.com/user-attachments/assets/f6d9b55f-e87e-4b20-a7c2-ed81e19414e4

