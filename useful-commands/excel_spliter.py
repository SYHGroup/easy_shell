# coding=UTF-8
import os
import tkinter
import tkinter.filedialog
import tkinter.simpledialog
import tkinter.ttk
from concurrent.futures import ProcessPoolExecutor

import pandas
from tqdm import tqdm


def subprocess(param):
    df, path, target, people, debug = param
    new_df = df[df[target].str.contains(people[0])]
    fp = f'{path if path else "."}/{"_".join(map(str,people))}.xlsx'
    if not debug:
        new_df.to_excel(fp, index=False)
    return True


def process(df, path, target, args=None, debug=False):
    if not target:
        return
    params = [df.columns[arg] for arg in args]
    peoples = list(set(zip(df.loc[:, target], *[df.loc[:, param] for param in params])))
    total = len(peoples)
    with ProcessPoolExecutor(
        max_workers=os.cpu_count() if os.cpu_count() else min(2, total)
    ) as executor:
        results = list(
            tqdm(
                executor.map(
                    subprocess, map(lambda x: (df, path, target, x, debug), peoples)
                ),
                total=total,
            )
        )
    return results


def main():
    root = tkinter.Tk()
    root.title("拆分Excel")
    frm = tkinter.ttk.Frame(root, padding=10)
    frm.grid()
    label = tkinter.ttk.Label(frm, text="选择列")
    label.grid(column=0, row=0)
    fileobj = tkinter.filedialog.askopenfile(
        mode="rb",
        title="选择分割文件",
        filetypes=["typeName {xls}", "typeName {xlsx}"],
        parent=frm,
    )
    if not fileobj:
        return
    df = pandas.read_excel(fileobj)
    column = list(df.columns)
    combobox = tkinter.ttk.Combobox(frm, state="readonly", values=column)
    combobox.grid(column=0, row=1)
    listbox = tkinter.Listbox(frm, selectmode="multiple")
    listbox.grid(column=0, row=2)
    for index, tile in enumerate(column):
        listbox.insert(index, tile)
    tkinter.ttk.Button(
        frm,
        text="确认",
        command=lambda: process(
            df,
            os.path.dirname(os.path.realpath(fileobj.name)),
            combobox.get(),  # str
            listbox.curselection(),  # tuple of index
            False,
        ),
    ).grid(column=0, row=3)
    root.mainloop()


if __name__ == "__main__":
    main()
