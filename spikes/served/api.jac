import json;
import from stdjac.server { HTTPMethod, restspec }
import from stdjac.graph { jobj }

node Item {
    has text: str;
}

@restspec(method=HTTPMethod.GET, path="/posts", envelope=False, produces="application/json")
def:pub list_posts -> str {
    return "[" + ",".join([n.text for n in [root.shared --> [?:Item]]]) + "]";
}

def:pub create(body: str) -> str {
    n = root.shared ++> Item(text=json.dumps(json.loads(body)));
    return jid(n);
}
