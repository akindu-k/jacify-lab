import http.server;
import xml.etree.ElementTree;
import re;

def one_level -> re.Pattern {
    return re.compile("a");
}

def two_levels(s: http.server.HTTPServer) -> int {
    return s.server_port;
}

def three_levels(e: xml.etree.ElementTree.Element) -> str {
    return e.tag;
}

with entry {
    print(one_level().pattern);
}
