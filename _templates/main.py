# main.py
# Located at src\{project_name}\main.py

from {package}.{module-name} import {main-function-name}

if __name__ == "__main__":

    print("INTRODUCING...") ## Some amount of introductory text
    
    print("""
    {project-name} Copyright (C) {year}  {author} <{email}> under GNU GPL v3.0.
    
    This program comes with ABSOLUTELY NO WARRANTY.
    
    This is free software, and you are welcome to redistribute it
    under certain conditions, in particular it may not be incorporated into
    proprietary programs.
    
    For full warranty, enter 'w' or see 'LICENSE.txt' that came with this package.
    """)
    
    warranty = input("\t >>>").strip().lower()
    
    if warranty == 'w':
        with open("LICENSE.txt", 'r', encoding='utf-8') as file:
            content = file.read()
            print(content)
            input("\n\n\t>>> Press enter to continue...")
        

    print({main-function-name}({args})) ## EDIT THIS LINE

    input("\nPress Enter to exit...")
