
## Dictionary Directorory for Word Game

Each server program recognizes a file named `<locale-code>-words.txt` in
its own 'dict' directory as the word list for the language designated by _locale-code_.
However, these are generally symbolic links to the dictionaries in the 
main 'dict' directory of the project, $WORKSPACE/dict.

Currently we only have an English dictionary:

- moby-english.txt - 
    
    Derived from CROSSWD.TXT of the project Gutenberg Moby free ebook: 
    http://www.gutenberg.org/files/3201/3201.txt
    http://www.gutenberg.org/files/3201/files/CROSSWD.TXT.
      
      `dos2unix CROSSWD.TXT`

    Note other files in the ebook may contain special characters. If you 
    decide to use them, remove the words with special characters:
    
      `egrep "^[a-zA-Z]+$" file 


To experiment with different dictionaries, symbolically link 
`<server-dir>/dict/<local-code>-words.txt` to your own word file.

For example, to use the English spell checker dictionary on unix-based platforms
for the scala-server, link as follows: 

    `ln -s /usr/share/dict/words $WORKSPACE/scala-server/dict/en-words.txt`

### Preprocessing the Dictionary

To aid the matching algorithms the dictionary is preprocessed by computing for 
each word all its "masked" versions, versions of the word in which up to N 
characters are replaced with blanks. These can then be matched with the contents
of the board's strips. The default value of N is 3. The preprocessed version 
of the dictionary is called `<locale-code>-masked-words.txt`. See the 
script `preprocess-masked-words.sh` in each server project. 

Ideally, the dictionary would be preprocessed on each deployment.
But preprocessing takes too long and would hamper quick turaround in 
the development process. Therefore, we keep the zipped version of the 
default masked words file in git and unzip it in deployment. The 
default masked words file itself is too large for github.

What this means that whenever the dictionary is 
modified, the default masked words file must be recomputed 
and its zipped version added to git. This has not been automated 
as yet as part of the build process. TBD.
