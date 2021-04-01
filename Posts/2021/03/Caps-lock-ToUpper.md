---
post_title: Can I Enable the Caps Lock Key?
username: tfl@psp.co.uk
Catagories: PowerShell
tags: Caps Lock, string, ToUpper()
Summary: How to enable all upper case input
---

**Q:** I have a script where users enter some information.
This information needs to be entered in all capital letters, so my instructions say, “Please make sure the Caps Lock key is on before entering the information.”
They don’t always do that, however.
Is there a way to turn the Caps Lock key on and off using a script?

**A:**  I don't know how to run the key off and on, but with PowerShell, there is a way to mimic the effect of turning on the Caps Lock key.

## User Input Considered Harmful

Let's start with the observation that all user input is harmful.
One of my earliest IT heroes, Edsger Dijkstra, published a seminal letter [Go To Statement Considered Harmful](https://homepages.cwi.nl/~storm/teaching/reader/Dijkstra68.pdf) in 1968 which began the structured programming revolution.
And this is one reason, by the way, why PowerShell has no goto statement.
The phrase "Considered Harmful" is also a well-known phrase that has a Wikipedia entry at [Considered Harmful](https://wikipedia.org/wiki/Considered_harmful#:~:text=Considered%20harmful%20was%20popularized%20among,the%20day%20and%20advocated%20structured).
In general, I consider all user input potentially harmful, capable of doing damage until and unless you thoroughly validate it first.

## Is User Input Really Harmful?

I was a verification programmer at university and got paid an hourly rate plus a bonus for finding bugs.
I made far more than my hourly wage by simply testing conditions outside what the developers considered "normal".
In other words potentially harmful.

If an instruction said, "Enter a number between 1 and 6", I tried -124, 0, 7, 42, 999999, and so on.
This approach inevitably led to several bugs (and several nice bug bounties).
Ever since then, I have always taught my students never ever to accept user input unchecked.
And that includes having all upper case input if that is what your application requires.

Another example of unchecked user input being harmful is SQL injection attacks.
You can read more about these attacks and how you can prevent it at [What is SQL Injection (SQLi) and How to Prevent It](https://www.acunetix.com/websitesecurity/sql-injection/)

So, in general, you should never trust any user input without validating it first.
Although you ask the user to type her name in all upper case, I'll bet that many just won't.

So what does the Caps Lock actually do?
When you type characters into a form or a console, you might type them like this:

```powershell-console
this is my sentence.
```

If you switch on the Caps Lock key, the operating system and your hardware makes those characters appear like this:

```console
THIS IS MY SENTENCE.
```

So how can we achieve that same effect in a script?
Simple: we accept the input as the user typed it.
Then we make sure it's all upper case before using it.

Let's start with getting the user input in the first place.

## Getting User Input

There are several ways to get user input from within a script.
A common approach with PowerShell scripts is to use the `Read-Host` command.
This cmdlet reads a line of input from the console and returns it to the script as a string.
For more information on this cmdlet, see the [Read-Host help file](https://docs.microsoft.com/powershell/module/microsoft.powershell.utility/read-host).

There are other ways to get user input, such as using [Windows Forms](https://docs.microsoft.com/powershell/scripting/samples/creating-a-custom-input-box) or WPF.
You might even use a legacy [Visual Basic `Inputbox`](https://docs.microsoft.com/dotnet/api/microsoft.visualbasic.interaction.inputbox).
But with each of these methods, you still have the underlying issue of making sure the string the user enters is all upper-case before you use it further.

Suppose you wanted to ask the user for their name (and you really need it to be upper case).
You could ask for, accept, and then display user input like this:

```powershell-console
PS C:\Foo> $Answer = Read-Host -Prompt 'Please Enter Your Name In ALL Upper case'
Please Enter Your Name In ALL Upper case: Thomas Lee
PS C:\Foo> $Answer
Thomas Lee
```

But that is not in upper case, I hear you say.
Yes, true - but there is just one more step.
Be patient, grasshopper.

## Converting a String to Upper Case

As I mentioned, when you use `Read-Host`, PowerShell returns the input to you as a string.
Even if you enter a number (say 42) PowerShell still treats this as a string containing two characters, like this:

```powershell-console
PS C:\> $Answer = Read-Host -Prompt "Please Enter Your Name In ALL Upper case"
Please Enter Your Name In ALL Upper case: 42
PS C:\> $Answer.GetType().FullName
System.String
```

This matters because the `System.String` .NET class has a very useful method, `ToUpper()`.
The `ToUpper()` method converts the string to all upper case and returns a new, all upper case, string.
So to convert the string you entered and stored in `$Answer`, you use the `ToUpper()` method like this:

```powershell-console
PS C:\> $Answer = Read-Host -Prompt 'Enter Your Name In ALL Upper Case'
Enter Your Name In ALL Upper Case: Thomas Lee
PS C:\> $Answer
Thomas Lee
PS C:\> $Answer = $Answer.ToUpper()  # convert to all upper case.
PS C:\> $Answer
THOMAS LEE
```

## Strings are Immutable in .NET

In .NET and PowerShell, a string is immutable
Once created, you can't change a System.String in memory after you define it.

If you assign a string variable a new value (the old value plus a character), .NET creates an all-new string with same name) and marks the older string as out of scope and available for garbage collection.
This is generally not an issue in cases such as wanting to ensure user input is all upper-case.

But if you have a script that makes a very large number of changes to any `System.String` object, you could encounter performance issues.
In such cases, you can use the .NET `System.Text.StringBuilder` class representaing mutable string of characters.
This class can provide significant performance gains in such scenarios.
For more information on the `StringBuilder` class, see [StringBuilder Class documentation page](https://docs.microsoft.com/dotnet/api/system.text.stringbuilder)
I plan to do another blog post on the differences.

## Strings and Methods

.NET strings also have other methods, including `ToLower()` that change a string to all lower case.
You can always discover the available methods of a string (or any other variable type) by piping the variable to `Get-Member`.
Like this:

```powershell-console
PS C:\ $Answer | Get-Member -MemberType Method

   TypeName: System.String

Name                 MemberType Definition
----                 ---------- ----------
Clone                Method     System.Object Clone(), System.Object ICloneable.Clone()
CompareTo            Method     int CompareTo(System.Object value), int CompareTo(string strB), int IComparabl…
Contains             Method     bool Contains(string value), bool Contains(string value, System.StringComparis…
CopyTo               Method     void CopyTo(int sourceIndex, char[] destination, int destinationIndex, int cou…
EndsWith             Method     bool EndsWith(string value), bool EndsWith(string value, System.StringComparis…
EnumerateRunes       Method     System.Text.StringRuneEnumerator EnumerateRunes()
Equals               Method     bool Equals(System.Object obj), bool Equals(string value), bool Equals(string …
GetEnumerator        Method     System.CharEnumerator GetEnumerator(), System.Collections.IEnumerator IEnumera…
GetHashCode          Method     int GetHashCode(), int GetHashCode(System.StringComparison comparisonType)
GetPinnableReference Method     System.Char&, System.Private.CoreLib, Version=5.0.0.0, Culture=neutral, Public…
GetType              Method     type GetType()
GetTypeCode          Method     System.TypeCode GetTypeCode(), System.TypeCode IConvertible.GetTypeCode()
IndexOf              Method     int IndexOf(char value), int IndexOf(char value, int startIndex), int IndexOf(…
IndexOfAny           Method     int IndexOfAny(char[] anyOf), int IndexOfAny(char[] anyOf, int startIndex), in…
Insert               Method     string Insert(int startIndex, string value)
IsNormalized         Method     bool IsNormalized(), bool IsNormalized(System.Text.NormalizationForm normaliza…
LastIndexOf          Method     int LastIndexOf(char value), int LastIndexOf(char value, int startIndex), int …
LastIndexOfAny       Method     int LastIndexOfAny(char[] anyOf), int LastIndexOfAny(char[] anyOf, int startIn…
Normalize            Method     string Normalize(), string Normalize(System.Text.NormalizationForm normalizati…
PadLeft              Method     string PadLeft(int totalWidth), string PadLeft(int totalWidth, char paddingCha…
PadRight             Method     string PadRight(int totalWidth), string PadRight(int totalWidth, char paddingC…
Remove               Method     string Remove(int startIndex, int count), string Remove(int startIndex)
Replace              Method     string Replace(string oldValue, string newValue, bool ignoreCase, cultureinfo …
Split                Method     string[] Split(char separator, System.StringSplitOptions options), string[] Sp…
StartsWith           Method     bool StartsWith(string value), bool StartsWith(string value, System.StringComp…
Substring            Method     string Substring(int startIndex), string Substring(int startIndex, int length)
ToBoolean            Method     bool IConvertible.ToBoolean(System.IFormatProvider provider)
ToByte               Method     byte IConvertible.ToByte(System.IFormatProvider provider)
ToChar               Method     char IConvertible.ToChar(System.IFormatProvider provider)
ToCharArray          Method     char[] ToCharArray(), char[] ToCharArray(int startIndex, int length)
ToDateTime           Method     datetime IConvertible.ToDateTime(System.IFormatProvider provider)
ToDecimal            Method     decimal IConvertible.ToDecimal(System.IFormatProvider provider)
ToDouble             Method     double IConvertible.ToDouble(System.IFormatProvider provider)
ToInt16              Method     short IConvertible.ToInt16(System.IFormatProvider provider)
ToInt32              Method     int IConvertible.ToInt32(System.IFormatProvider provider)
ToInt64              Method     long IConvertible.ToInt64(System.IFormatProvider provider)
ToLower              Method     string ToLower(), string ToLower(cultureinfo culture)
ToLowerInvariant     Method     string ToLowerInvariant()
ToSByte              Method     sbyte IConvertible.ToSByte(System.IFormatProvider provider)
ToSingle             Method     float IConvertible.ToSingle(System.IFormatProvider provider)
ToString             Method     string ToString(), string ToString(System.IFormatProvider provider), string IC…
ToType               Method     System.Object IConvertible.ToType(type conversionType, System.IFormatProvider …
ToUInt16             Method     ushort IConvertible.ToUInt16(System.IFormatProvider provider)
ToUInt32             Method     uint IConvertible.ToUInt32(System.IFormatProvider provider)
ToUInt64             Method     ulong IConvertible.ToUInt64(System.IFormatProvider provider)
ToUpper              Method     string ToUpper(), string ToUpper(cultureinfo culture)
ToUpperInvariant     Method     string ToUpperInvariant()
Trim                 Method     string Trim(), string Trim(char trimChar), string Trim(Params char[] trimChars)
TrimEnd              Method     string TrimEnd(), string TrimEnd(char trimChar), string TrimEnd(Params char[] …
TrimStart            Method     string TrimStart(), string TrimStart(char trimChar), string TrimStart(Params c…
```

If you look carefully at this list, you can see methods that convert a string to different kinds of numbers.
These methods would help you convert the string of 2 characters (e.g. 42) into an integer number.
That could well be the subject of another article that shows you how to achieve this.

## Summary

Turning the Caps Lock key on is not something I know how to do.
And if you did, it might confuse the user, for example if she sees the Caps Lock indicator light up on their keyboard.
As well, you would need to turn it off afterwards.

Rather then depending on any user to always do the right thing, you can always ensure that the input is indeed in all upper case.
Never trust user input without validating it first.

## Tip of the Hat

This article is based on an earlier article here: [Can I Enable the Caps Lock Key?](https://devblogs.microsoft.com/scripting/can-i-enable-the-caps-lock-key/).
I re-developed the article around PowerShell.
