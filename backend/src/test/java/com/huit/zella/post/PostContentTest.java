package com.huit.zella.post;

import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class PostContentTest {
    private String rich(String ops) { return PostContent.PREFIX + ops; }
    @Test void legacyPlainTextStillWorks() { assertEquals("Bài viết cũ\nĐoạn hai", PostContent.validate("Bài viết cũ\nĐoạn hai")); }
    @Test void preservesRichTextAndCloudImage() {
        String content = rich("[{\"insert\":\"Tiêu đề\",\"attributes\":{\"bold\":true}},{\"insert\":\"\\n\",\"attributes\":{\"header\":2}},{\"insert\":{\"image\":\"https://cloud.example/photo.png\"}},{\"insert\":\"\\n\"}]");
        assertEquals(content, PostContent.validate(content));
    }
    @Test void rejectsEmptyDocumentAndMalformedDelta() {
        for (String ops : new String[]{"[]", "{}", "not json", "[{\"insert\":\"\\n\"}]", "[{\"insert\":\"Text without terminal newline\"}]", "[{\"retain\":1}]"}) {
            assertThrows(BusinessException.class, () -> PostContent.validate(rich(ops)));
        }
    }
    @Test void rejectsUnsafeLinksAndLocalOrEmbeddedImages() {
        for (String url : new String[]{"javascript:alert(1)", "data:image/png;base64,abc", "file:///C:/image.png", "//evil.example/image.png", "https://user:password@example.com"}) {
            String image = rich("[{\"insert\":{\"image\":\""+url+"\"}},{\"insert\":\"\\n\"}]");
            assertThrows(BusinessException.class, () -> PostContent.validate(image));
            String link = rich("[{\"insert\":\"Text\",\"attributes\":{\"link\":\""+url+"\"}},{\"insert\":\"\\n\"}]");
            assertThrows(BusinessException.class, () -> PostContent.validate(link));
        }
    }
    @Test void rejectsUnsupportedEmbedsAndInvalidAttributeTypes() {
        for (String ops : new String[]{"[{\"insert\":{\"video\":\"https://example.com\"}},{\"insert\":\"\\n\"}]", "[{\"insert\":\"Text\\n\",\"attributes\":{\"bold\":{}}}]", "[{\"insert\":\"Text\\n\",\"attributes\":{\"header\":9}}]", "[{\"insert\":\"Text\\n\",\"attributes\":{\"indent\":100}}]"}) {
            assertThrows(BusinessException.class, () -> PostContent.validate(rich(ops)));
        }
    }
}
