# Writing your own Plugin

You can write your own plugin if you want to process requests before they get send, responses after they got received or if you want to provide an additional UI.

## Before implementing your own Plugin

Before implementing your own idea, you have to decide which Floret base protocol suits you best. You can also implement multiple.

**[InterceptingFloret](https://cauli.works/docs/Protocols/InterceptingFloret.html):** This protocol let's you process requests and responses.   
**[DisplayingFloret](https://cauli.works/docs/Protocols/DisplayingFloret.html):** This protocol let's you create a custom UIViewController for your floret.  
**[Floret](https://cauli.works/docs/Protocols/Floret.html):** The Floret protocol is the base for the protocols described above. It should not be implemented directly, since there will be no effect.

## Accessing the storage

Cauli manages the storage of `Record`s. Every `Record` selected by the [RecordSelector](https://cauli.works/docs/Structs/RecordSelector.html) is stored in memory. When displaying your [DisplayingFlorets](https://cauli.works/docs/Protocols/DisplayingFloret.html) ViewController you have access to the respective Cauli instance and thus to it's [Storage](https://cauli.works/docs/Protocols/Storage.html).
