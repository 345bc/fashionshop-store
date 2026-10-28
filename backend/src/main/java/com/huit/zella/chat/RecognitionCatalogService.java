package com.huit.zella.chat;

import com.huit.zella.product.ProductCardResponse;
import com.huit.zella.product.ProductService;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * Catalog lookup runs after inference, without holding a transaction during the AI request.
 */
@Service
public class RecognitionCatalogService {
    public record Suggestion(String label, String color, boolean colorMatched, List<ProductCardResponse> products) {
    }

    private final JdbcTemplate jdbc;
    private final ProductService products;

    public RecognitionCatalogService(JdbcTemplate jdbc, ProductService products) {
        this.jdbc = jdbc;
        this.products = products;
    }

    static List<String> keywords(String label) {
        return switch (label.trim().toLowerCase(Locale.ROOT)) {
            case "blazer" -> List.of("blazer");
            case "blouse" -> List.of("blouse", "áo kiểu");
            case "button-down" -> List.of("button-down", "áo sơ mi");
            case "cardigan" -> List.of("cardigan");
            case "hoodie" -> List.of("hoodie");
            case "jacket" -> List.of("jacket", "áo khoác");
            case "sweater" -> List.of("sweater", "áo len");
            case "tank" -> List.of("tank top", "áo ba lỗ", "áo sát nách");
            case "tee" -> List.of("áo thun", "áo phông", "t-shirt");
            case "jeans" -> List.of("jeans", "quần jean", "quần bò");
            case "joggers" -> List.of("jogger");
            case "leggings" -> List.of("legging");
            case "shorts" -> List.of("quần short", "quần đùi", "quần soóc");
            case "skirt" -> List.of("skirt", "chân váy");
            case "sweatpants" -> List.of("sweatpants", "quần nỉ");
            case "coat" -> List.of("măng tô", "mangto", "áo khoác dài", "trench coat", "overcoat");
            case "dress" -> List.of("dress", "đầm", "váy liền");
            default -> List.of();
        };
    }

    static List<String> colorKeywords(String color) {
        return switch (color.trim().toLowerCase(Locale.ROOT)) {
            case "black" -> List.of("black");
            case "white", "off white", "cream" -> List.of("white", "off white", "cream");
            case "gray", "grey", "grey melange", "charcoal", "silver", "blue gray", "blue grey" -> List.of("gray", "grey", "grey melange", "charcoal", "silver", "blue gray", "blue grey");
            case "blue", "navy blue", "turquoise blue", "teal", "ice blue" -> List.of("blue", "navy blue", "turquoise blue", "teal", "ice blue");
            case "green", "olive", "sea green", "lime green", "fluorescent green", "light green" -> List.of("green", "olive", "sea green", "lime green", "fluorescent green", "light green");
            case "red", "maroon", "burgundy" -> List.of("red", "maroon", "burgundy");
            case "pink", "rose", "magenta" -> List.of("pink", "rose", "magenta");
            case "purple", "lavender", "mauve", "periwinkle" -> List.of("purple", "lavender", "mauve", "periwinkle");
            case "yellow", "mustard", "gold" -> List.of("yellow", "mustard", "gold");
            case "orange", "rust" -> List.of("orange", "rust");
            case "brown", "coffee brown", "mushroom brown", "tan" -> List.of("brown", "coffee brown", "mushroom brown", "tan");
            case "beige", "khaki", "nude", "skin", "taupe", "peach" -> List.of("beige", "khaki", "nude", "skin", "taupe", "peach");
            case "multi" -> List.of("multi");
            default -> List.of();
        };
    }

    public List<Suggestion> suggest(List<ImageRecognitionService.Detection> detections) {
        List<Suggestion> result = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        for (var detection : detections.stream().sorted(Comparator.comparingDouble(ImageRecognitionService.Detection::confidence).reversed()).toList()) {
            var terms = keywords(detection.label());
            String color = detection.colors().stream().max(Comparator.comparingDouble(ImageRecognitionService.Color::confidence))
                    .map(ImageRecognitionService.Color::label).orElse("");
            if (terms.isEmpty() || !seen.add(detection.label() + ":" + color)) continue;
            var colors = colorKeywords(color);
            List<Long> ids = colors.isEmpty() ? List.of() : find(terms, colors);
            boolean colorMatched = !ids.isEmpty();
            if (ids.isEmpty()) ids = find(terms, List.of());
            result.add(new Suggestion(detection.label(), color, colorMatched, ids.isEmpty() ? List.of() : products.featuredCards(ids)));
            if (result.size() == 3) break;
        }
        return result;
    }

    private List<Long> find(List<String> terms, List<String> colors) {
        List<Object> args = new ArrayList<>();
        String category = contains("c.name", terms, args);
        String name = contains("p.name", terms, args);
        String color = "1=1";
        if (!colors.isEmpty()) {
            // Match complete catalog color names so Blue does not also match Blue Gray.
            color = "LOWER(LTRIM(RTRIM(col.name))) IN (" + String.join(",", Collections.nCopies(colors.size(), "?")) + ")";
            args.addAll(colors);
        }
        // Color and available stock must belong to the SAME active variant.
        String sql = "SELECT TOP (6) p.id FROM products p JOIN categories c ON c.id=p.category_id "
                + "WHERE p.is_active=1 AND c.is_active=1 AND (" + category + " OR " + name + ") "
                + "AND EXISTS (SELECT 1 FROM product_variants v JOIN color col ON col.id=v.color_id "
                + "WHERE v.product_id=p.id AND v.is_active=1 AND v.stock_quantity>v.reserved_quantity AND (" + color + ")) "
                + "ORDER BY CASE WHEN " + contains("c.name", terms, args) + " THEN 0 ELSE 1 END, p.id DESC";
        return jdbc.query(sql, (rs, row) -> rs.getLong(1), args.toArray());
    }

    private static String contains(String column, List<String> terms, List<Object> args) {
        List<String> predicates = new ArrayList<>();
        for (String term : terms) {
            predicates.add("LOWER(" + column + ") LIKE ?");
            args.add("%" + term.toLowerCase(Locale.ROOT) + "%");
        }
        return "(" + String.join(" OR ", predicates) + ")";
    }
}
