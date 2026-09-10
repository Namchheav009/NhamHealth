package com.nhamhealth.nhamhealth_api;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@ActiveProfiles("supabase")
@SpringBootTest(properties = {
                "spring.flyway.enabled=true",
                "spring.jpa.hibernate.ddl-auto=none",
                "logging.level.root=WARN",
                "app.seed.admin-enabled=false"
})
class MigrationSchemaProbeTests {

        private static final List<String> TABLES = List.of(
                        "ingredient_translations",
                        "meal_category_translations",
                        "meal_ingredient_translations",
                        "meal_translations",
                        "mood_translations",
                        "recipe_step_translations",
                        "tag_translations");

        @Autowired
        private JdbcTemplate jdbc;

        @Test
        void printTranslationSchema() {
                for (String table : TABLES) {
                        System.out.println("SCHEMA_TABLE=" + table);
                        System.out.println("ROW_COUNT=" + jdbc.queryForObject(
                                        "select count(*) from public." + table, Long.class));
                        printRows("COLUMNS", """
                                        select column_name, data_type, udt_name, is_nullable, column_default,
                                               character_maximum_length, numeric_precision, numeric_scale,
                                               is_identity, identity_generation
                                        from information_schema.columns
                                        where table_schema = 'public' and table_name = ?
                                        order by ordinal_position
                                        """, table);
                        printRows("CONSTRAINTS", """
                                        select c.conname, c.contype, pg_get_constraintdef(c.oid) as definition
                                        from pg_constraint c
                                        join pg_class t on t.oid = c.conrelid
                                        join pg_namespace n on n.oid = t.relnamespace
                                        where n.nspname = 'public' and t.relname = ?
                                        order by c.conname
                                        """, table);
                        printRows("INDEXES", """
                                        select indexname, indexdef
                                        from pg_indexes
                                        where schemaname = 'public' and tablename = ?
                                        order by indexname
                                        """, table);
                }
        }

        private void printRows(String label, String sql, String table) {
                for (Map<String, Object> row : jdbc.queryForList(sql, table)) {
                        System.out.println(label + "=" + row);
                }
        }
}
