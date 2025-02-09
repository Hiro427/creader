### About 

I wrote this project to learn Bash, it allows the reading downloaded manga from [MangaDex](https://mangadex.org/)  


### Please Read

**As of February 8th, 2025**  

I'm still learning all the quirks of Bash, so the Keymaps situation is far from perfect. See Keymaps Section for more details. 

Currently Manga can only be read after being downloaded.

I am working on "Live Reading", I'm just a bit burnt out with this project at the moment. 

Keymaps situation is far from perfect but 

### Features 
- Downloading All or Selected Manga 
- Reading Manga 
- Save Reading Sessions 


### Keymaps/Navigation 

In some states of the app Ctrl+C works correctly in only in some cases, I think it has to do with gum. As a result I've added in options to gum menus for Exiting and Going Back. 

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

    `wget "https://raw.githubusercontent.com/Hiro427/creader/refs/heads/main/install.sh"`

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
    `cd` && `git clone https://github.com/Hiro427/creader.git` # clone the repo  
    `cd creader/`


    #Make the executable 
    `chmod +x creader.sh`

    #Copy to PATH
    `sudo cp ./creader.sh /usr/local/bin/creader`

    #Move the ASCII Header to the config directory 
    `cp header.txt ~/.config/creader/`

</details>





