# FAQ #

Okay, so technically, there aren't any frequently asked questions yet.  Here are some that I think you'd want to know.

---


  * **How is this project related to OpenCV?**
> It's not, really.  Both projects use the same underlying ideas (Haar Classifier cascades scanned across input images), but share no implementation code.  Deface has been designed to be compatible with classifier xml files from OpenCV for convenience.

  * **Why should I use this instead of server-side detection?**
> Deface is entirely client-side, allowing essentially unlimited concurrent users.

  * **Why _shouldn't_ I use this?**
> Right now, it's pretty slow compared to various server-side detection frameworks.  If speed is your primary concern, you may be disappointed.