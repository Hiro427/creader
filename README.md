### About 

It allows reading and downloading manga from [MangaDex](https://mangadex.org/)  

https://github.com/user-attachments/assets/55cc617c-1e7c-4606-a41f-0c21dc359ae2



### Please Read

**As of February 8th, 2025**  

I wrote this project to learn Bash using only Non AI sources, if you see anything I my might've missed or something to improve the script, feel free to open an issue. 

The Keymaps situation is far from perfect. Sometimes depending on the current application state, Ctrl+c doesn't stop all of the processes. See Keymaps Section for more details. 

Currently Manga can only be read after being downloaded.

I am working on "Live Reading", I'm just a bit burnt out with this project at the moment. But I'll get on it as soon as possible. 

### Features 
- Downloading All or Selected Manga 
- Reading Manga 
- Save Reading Sessions 


### Keymaps/Navigation 

#### Gum Keymaps

*Gum is used to generate the nicer menus in the script*


**NOTE: Gum has its own keymaps that are used, these are builtin and as far as I know they cannot be changed. They are printed below each menu** 

**Example**

In the Manga Chapter selection menu when selecting what to download:

```
ctrl+a - select all 
tab - select specifc entries (use must first use escape to temporarily disable the fuzzy searching before using tab, fuzzy search can be used again after pressing '/') 
```
Gum Bindings are already show in each menu, below you will see some of my own binding, my bindings cannot be used in conjuction with gum's bindings or vice versa. I know this maybe confusing but this is the best I could do at the moment, until my rewrite in go (TBD).

Only in some states of the app does Ctrl+C works correctl, I think it has to do with how I'm using gum, but I'm not sure. As a result I've added in options to gum menus for Exiting and Going Back. 

<details>
<summary>While Reading Manga</summary>

```
q/Ctrl+c - Quit/Exit 
j/down   - next page 
k/up     - previous page 
h/left   - previous chapter 
l/right  - next chapter
r        - load saved sessions menu
s        - save current reading session
m        - go back to main menu
b        - go back to chapter selection for current manga
```
</details>

<details>
<summary>Manga Info Preview Page</summary>

###### **This is shown when selecting manga to download** 

```
q/Ctrl+c - Quit/Exit
b        - back to manga selection menu 
enter    - selects the manga 
any key  - returns to main menu
```
</details>

<details>
<summary>When passing a .cbz file as an argument</summary>

```
j/down   - next page 
k/up     - previous page 
q/ctrl+c - Quit/Exit
m        - Main Menu
```
</details>

### Installation 

#### Set Environment Variable 

- This is the location of where the downloaded manga will be stored 
- Make sure the directory exists

`export MANGA_DL_DIR="$HOME/Downloads/Manga/"` 


#### There are two ways to install, via the script and manually

<details>
<summary>Script</summary>

    Be sure to read the script before running it!

    wget "https://raw.githubusercontent.com/Hiro427/creader/refs/heads/main/install.sh" 
    chmod +x install.sh 
    ./install.sh
    

</details>

<details> 
<summary>Manual</summary>  

    You can read through the script yourself and copy and make the commands, or follow below.
    
    cd ~/.config && mkdir creader #make creader directory in .config directory

    #make directories, be sure to check spelling, these directories are coded in the main script
    mkdir active/
    mkdir sessions/
    mkdir tmp/ 

    #clone repo 
    cd && git clone https://github.com/Hiro427/creader.git
    `cd creader/`


    #Make the script an executable 
    chmod +x creader.sh

    #Copy script to PATH
    sudo cp ./creader.sh /usr/local/bin/creader

    #Move the ASCII Header to the config directory 
    cp header.txt ~/.config/creader/

</details>





