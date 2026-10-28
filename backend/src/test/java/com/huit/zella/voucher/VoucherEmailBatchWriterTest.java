package com.huit.zella.voucher;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import javax.sql.DataSource;
import java.sql.*;
import java.time.Instant;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class VoucherEmailBatchWriterTest {
    private final DataSource source = mock(DataSource.class);
    private final Connection connection = mock(Connection.class);
    private final PreparedStatement ledger = mock(PreparedStatement.class);
    private final PreparedStatement outbox = mock(PreparedStatement.class);
    private final VoucherEmailBatchWriter writer = new VoucherEmailBatchWriter(new JdbcTemplate(source));
    private final Instant now = Instant.parse("2026-10-21T03:00:00Z");
    private final List<VoucherEmailBatchWriter.Message> messages = List.of(
            new VoucherEmailBatchWriter.Message("a@gmail.com", "GOLD", "Ưu đãi", "Mã giảm giá", now, now.plusSeconds(900)),
            new VoucherEmailBatchWriter.Message("b@gmail.com", "SILVER", "Ưu đãi", "Mã giảm giá", now.plusSeconds(3), now.plusSeconds(900)));

    @BeforeEach void setup() throws Exception {
        when(source.getConnection()).thenReturn(connection);
        when(connection.getAutoCommit()).thenReturn(true);
        when(ledger.getConnection()).thenReturn(connection);
        when(outbox.getConnection()).thenReturn(connection);
        var metadata = mock(DatabaseMetaData.class);
        when(connection.getMetaData()).thenReturn(metadata);
        when(metadata.supportsBatchUpdates()).thenReturn(true);
        when(metadata.getDatabaseProductName()).thenReturn("Microsoft SQL Server");
        when(connection.prepareStatement(startsWith("insert into voucher_email_recipients"))).thenReturn(ledger);
        when(connection.prepareStatement(startsWith("insert into email_outbox"))).thenReturn(outbox);
        when(ledger.executeBatch()).thenReturn(new int[]{1, 1});
        when(outbox.executeBatch()).thenReturn(new int[]{1, 1});
    }

    private void send() {
        new TransactionTemplate(new DataSourceTransactionManager(source))
                .executeWithoutResult(status -> writer.enqueue(1L, now, messages));
    }

    @Test void ledgerAndOutboxAreWrittenInBatchesAndCommittedTogether() throws Exception {
        send();
        verify(ledger, times(2)).addBatch(); verify(outbox, times(2)).addBatch();
        verify(ledger).executeBatch(); verify(outbox).executeBatch();
        verify(outbox, times(2)).setNString(2, "Ưu đãi");
        verify(outbox, times(2)).setNString(3, "Mã giảm giá");
        verify(outbox).setTimestamp(eq(4), eq(Timestamp.from(now.plusSeconds(3))), argThat(calendar -> calendar.getTimeZone().getID().equals("UTC")));
        var order = inOrder(ledger, outbox, connection);
        order.verify(ledger).executeBatch(); order.verify(outbox).executeBatch(); order.verify(connection).commit();
        verify(connection, never()).rollback();
    }

    @Test void outboxFailureRollsBackRecipientDeduplicationToo() throws Exception {
        when(outbox.executeBatch()).thenThrow(new SQLException("simulated database failure", "08000"));
        assertThrows(DataAccessException.class, this::send);
        verify(ledger).executeBatch();
        verify(connection).rollback(); verify(connection, never()).commit();
    }

    @Test void emptyBatchDoesNotTouchDatabase() {
        writer.enqueue(1L, now, List.of());
        verifyNoInteractions(source);
    }
}
